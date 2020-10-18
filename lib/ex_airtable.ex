defmodule ExAirtable do
  @moduledoc """
  Provides an interface to query Airtable bases/tables, and an optional server to cache the results of a table into memory for faster access and to avoid Airtable API access limitations.

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

  ## Caching

  To run a local caching server, you can include a reference to the `ExAirtable` cache server in your supervision tree, for example:

      defmodule My.Application do
        use Application

        def start(_type, _args) do
          children = [
            # ...

            # cache processes
            {ExAirtable.TableCache, table_module: MyApp.MyAirtable},
            {ExAirtable.TableCache, table_module: MyApp.MyOtherAirtable},

            # ...
          ]

          opts = [strategy: :one_for_one, name: PhoenixCms.Supervisor]
          Supervisor.start_link(children, opts)
        end

        # ...
      end

  ## Examples

  The codebase includes an example `Table` (`ExAirtable.Example.EnvTable`) that you can use to play around and get an idea of how the system works. This module uses environment variables as configuration. The included `Makefile` provides some quick command-line tools to run tests and a console with those environment variables pre-loaded. Simply edit the relevant environment variables in `Makefile` to point to a valid base/table name, and you'll be able to interact directly like this:

      # first, run `make console`, then...
     
      # to retrieve data directly from Airtable's API...
      iex> EnvTable.list
      %ExAirtable.Airtable.List{records: [%Record{}, %Record{}, ...]}

      iex> EnvTable.retrieve("rec12345")
      %ExAirtable.Airtable.Record{}

      # to start a caching server for your table...
      iex> ExAirtable.TableCache.start_link(table_module: EnvTable, sync_rate: :timer.seconds(5))

      # to get all records from the cache (without hitting the Airtable API)
      iex> TableCache.get_all(EnvTable)
      %ExAirtable.Airtable.List{}
  """

  alias ExAirtable.{Airtable, BaseQueue, TableCache}
  alias ExAirtable.RateLimiter.Request

  @doc """
  Create a record in your Airtable. See `Service.create/2` for details.
  """
  def create(table, %Airtable.List{} = list) do
    job = Request.create(
      {table, :create, [list]}, 
      {TableCache, :set_all, [table]}
    )
    BaseQueue.request(table, job)
  end

  @doc """
  Delete a single record (by ID) from an Airtable. If successful, the record will be deleted from the cache as well.
  """
  def delete(table, id) when is_binary(id) do
    job = Request.create(
      {table, :delete, [id]}, 
      {TableCache, :delete, [table]}
    )
    BaseQueue.request(table, job)
  end
	
  @doc """
  Get all records from the table cache
  """
	def list(table) do
    TableCache.list(table)
	end

  @doc """
  Retrieve a single record from the table cache.
  """
	def retrieve(table, key) when is_binary(key) do
    TableCache.retrieve(table, key)
	end

  @doc """
  Update a record in your Airtable. 

  One particular thing to note is that Airtable won't allow updates for records that pass calculated fields. The `objectionable_fields: ["list", "of", "fieldNames"]` option will allow you to point those out so that your update goes through.

  See `Service.create/2` for more details about options that can be passed.
  """
  def update(table, %Airtable.List{} = list, opts \\ []) do
    job = Request.create(
      {table, :update, [list, opts]}, 
      {TableCache, :update, [table]}
    )
    BaseQueue.request(table, job)
  end
end
