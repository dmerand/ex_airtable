defmodule ExAirtable do
  @moduledoc """
  Provides an interface to query Airtable bases/tables, and an optional server to cache the results of a table into memory for faster access and to avoid Airtable API access limitations.

  The preferred mode of operation is to run in rate-limited and cached mode, to ensure that no API limitations are hit. The functions in the `ExAirtable` base module will operate through the rate-limiter and cache by default.

  If you wish to skip rate-limiting and caching, you can simply hit the Airtable API directly and get nicely-wrapped results by using the `Table` endpoints directly (see below for setup).

  In either the direct-to-API or cached-and-rate-limited case, this library provides an `%Airtable.Record{}` and `%Airtable.List{}` struct which mirror the API results that Airtable provides. All results will be wrapped in those structs. We (currently) make no effort to convert Airtable's generic data representation into an app's local data domain, but instead provide a sane default that can be easily extended (via Ecto schemas for example). We also provide some convenience methods for things like record field retrieval and relationship matching (see below).

  ## Setup

  Generally, you'll need to do two things:

  1. Add a `%ExAirtable.Config.Base{}` into your application configuration for each Airtable base that you intend to reference.
  2. For each table within a base that you intend to query, define a module in your codebase that implements the `ExAirtable.Table` behaviour (by running `use ExAirtable.Table` and implementing the `base()` and `table_name()` callbacks).

  For example:

      defmodule MyApp.MyAirtable do
        use ExAirtable.Table

        def base, do: %ExAirtable.Config.Base{
          id: "your base ID",
          api_key: "your api key"
        }

        def name, do: "Table Name"
      end

  With this module defined, you can hit the API directly (skipping rate-limiting and caching) like so:

      iex> MyApp.MyAirtable.list()
      %Airtable.List{}

      iex> MyApp.MyAirtable.retrieve("rec12345")
      %Airtable.Record{}

  ## Rate-Limiting and Caching

  Activating the `ExAirtable.Supervisor` in your supervision tree (passing it any tables you've defined as above) confers a few advantages:

  1. All tables are automatically synchronized to a local (ETS) cache for much faster local response times.
  2. All requests are automatically rate-limited (5 requests per second per Airtable base) so as not to exceed Airtable API rate limits.
  3. Record creation requests are automatically split into batches of 10 (Airtable will reject larger requests).

  To run a local caching server, you can include a reference to the `ExAirtable` supervisor in your supervision tree, for example:

      defmodule My.Application do
        use Application

        def start(_type, _args) do
          children = [
            # ...

            # Configure caching and rate-limiting processes
            {ExAirtable.Supervisor, {[MyApp.MyAirtable, MyApp.MyOtherAirtable, ...], sync_rate: :timer.seconds(15)}},

            # ...
          ]

          opts = [strategy: :one_for_one, name: MyApplication.Supervisor]
          Supervisor.start_link(children, opts)
        end

        # ...
      end
      
  Note that the `:sync_rate` (the rate at which tables are refreshed from Airtable) is optional and will default to 30 seconds if omitted. 

  Once you have configured things this way, you can call `ExAirtable` directly, and get all of the speed and reliability benefits of caching and rate-limiting.

      iex> ExAirtable.list(MyApp.MyAirtable)
      {:ok, %ExAirtable.Airtable.List{}}
      
      iex> ExAirtable.retrieve(MyApp.MyAirtable, "rec12345")
      {:ok, %ExAirtable.Airtable.Record{}}

  ## Examples + Playing Around

  The codebase includes an example `Table` (`ExAirtable.Example.EnvTable`) that you can use to play around and get an idea of how the system works. This module uses environment variables as configuration. The included `Makefile` provides some quick command-line tools to run tests and a console with those environment variables pre-loaded. Simply edit the relevant environment variables in `Makefile` to point to a valid base/table name, and you'll be able to interact directly like this:

      # first, run `make console`, then...
     
      # retrieve data directly from Airtable's API...
      iex> EnvTable.list
      %ExAirtable.Airtable.List{records: [%Record{}, %Record{}, ...]}

      iex> EnvTable.retrieve("rec12345")
      %ExAirtable.Airtable.Record{}

      # start a caching and rate-limiting server 
      iex> ExAirtable.Supervisor.start_link([EnvTable])

      # get all records from the cache (without hitting the Airtable API)
      iex> ExAirtable.list(EnvTable)
      %ExAirtable.Airtable.List{}
      
  Because certain tasks such as retrieving fields and finding related data happen so often, we put in a few convenience functions to make those jobs easier.

      # grab a field from a record
      iex> ExAirtable.Airtable.Record.get(record, "Users")
      ["rec1234", "rec3456"]

      # find related table data based on a record ID
      iex> ExAirtable.Airtable.List.filter_relations(list, "Users", "rec1234")
      [%Record{fields: %{"Users" => ["rec1234", "rec3456"]}}, ...]

  See the `ExAirtable.Airtable.List` and `ExAirtable.Airtable.Record` module documentation for more information.
  """

  alias ExAirtable.{Airtable, RateLimiter, TableCache}
  alias ExAirtable.RateLimiter.Request

  @doc """
  Create one or more records in your Airtable from an %Airtable.List{} request. 

  If your list includes more than 10 records, the request will be split so as not to be rejected by the Airtable API.

  This call is asynchronous, but the local cache will be automatically updated with any new records when the callback is successful.

  See `Service.create/2` for more details.
  """
  def create(table_module, %Airtable.List{} = list) do
    Enum.chunk_every(list.records, 10)
    |> Enum.each(fn records ->
      smaller_list = %{list | records: records}

      job =
        Request.create(
          {table_module, :create, [smaller_list]},
          {TableCache, :set_all, [table_module]}
        )

      RateLimiter.request(table_module, job)
    end)
  end

  @doc """
  Delete a single record (by ID) from an Airtable. 

  If successful, the record will be deleted from the cache as well.

  This call is asynchronous, but the local cache will be automatically updated when the callback is successful.
  """
  def delete(table_module, id) when is_binary(id) do
    job =
      Request.create(
        {table_module, :delete, [id]},
        {TableCache, :delete, [table_module]}
      )

    RateLimiter.request(table_module, job)
  end

  @doc """
  Get all records from the given table module's cache

  ## Examples

      iex> list(EnvTable)
      {:ok, %Airtable.List{}}
  """
  def list(table_module) do
    TableCache.list(table_module)
  end

  @doc """
  Same as `list/0`, but raises on error.
  """
  def list!(table_module) do
    {:ok, list} = TableCache.list(table_module)
    list
  end

  @doc """
  Retrieve a single record from the table module's cache.

  ## Examples

      iex> retrieve(EnvTable, "recLIY1WLOs8ocOAq")
      {:ok, %Airtable.Record{}}
  """
  def retrieve(table_module, key) when is_binary(key) do
    TableCache.retrieve(table_module, key)
  end

  @doc """
  Same as `retrieve/1`, but raises on error.
  """
  def retrieve!(table_module, key) when is_binary(key) do
    {:ok, record} = TableCache.retrieve(table_module, key)
    record
  end

  @doc """
  Update a record in your Airtable. 

  This call is asynchronous, but the local cache will be automatically updated when the callback is successful.

  One particular thing to note is that Airtable won't allow updates for records that pass calculated fields. The `objectionable_fields: ["list", "of", "fieldNames"]` option will allow you to point those out so that your update goes through.

  See `Service.create/2` for more details about options that can be passed.
  """
  def update(table_module, %Airtable.List{} = list, opts \\ []) do
    job =
      Request.create(
        {table_module, :update, [list, opts]},
        {TableCache, :update, [table_module]}
      )

    RateLimiter.request(table_module, job)
  end
end
