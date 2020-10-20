# ExAirtable

Provides an interface to query Airtable bases/tables, and an optional server to cache the results of a table into memory for faster access and to avoid Airtable API access limitations.

The preferred mode of operation is to run in rate-limited and cached mode, to ensure that no API limitations are hit. The functions in the `ExAirtable` base module will operate through the rate-limiter and cache by default.

If you wish to skip rate-limiting and caching, you can simply hit the Airtable API directly and get nicely-wrapped results by using the `Table` endpoints directly (see below for setup).

In either the direct-to-API or cached-and-rate-limited case, this library provides an `%Airtable.Record{}` and `%Airtable.List{}` struct which mirror the API results that Airtable provides. All results will be wrapped in those structs. We (currently) make no effort to convert Airtable's generic data representation into an app's local data domain, but instead provide a sane default that can be easily extended (via Ecto schemas for example).

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
          {ExAirtable.Supervisor, {[MyApp.MyAirtable, MyApp.MyOtherAirtable, ...], [delete_on_refresh: false, sync_rate: :timer.seconds(15)]}},

          # ...
        ]

        opts = [strategy: :one_for_one, name: MyApplication.Supervisor]
        Supervisor.start_link(children, opts)
      end

      # ...
    end
    
Note that the `:sync_rate` (the rate at which tables are refreshed from Airtable) is optional and will default to 30 seconds if omitted. Similarly `:delete_on_refresh` defaults to `true`, meaning that each sync from Airtable will destroy and re-create the local cache. Set it to `false` to keep your cache from churning too hard if you don't need to sync deletions that happen on the Airtable side in real-time.

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
      
## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `ex_airtable` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:ex_airtable, "~> 0.1.0"}
  ]
end
```

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at [https://hexdocs.pm/ex_airtable](https://hexdocs.pm/ex_airtable).

## Testing

The test suite is designed to work both on local mocks and on an (optional) external Airtable source.

If you'd like to only run local tests without hitting any external APIs, run `make tests_no_external`.

If you'd like to run external APIs, you'll need to update the environment variables in the `Makefile` to point to your example Airtable.  After updating the test environment data in `Makefile`, you can run `make tests`.
