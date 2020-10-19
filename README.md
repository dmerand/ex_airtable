# ExAirtable

Provides an interface to query Airtable bases/tables, and an optional server to cache the results of a table into memory for faster access and to avoid Airtable API access limitations.

The preferred mode of operation is to run in rate-limited and cached mode, to ensure that no API limitations are hit. The functions in this module will operate through the rate-limiter and cache by default.

If you wish to skip rate-limiting and caching, you can simply hit the Airtable API directly and get nicely-wrapped results by using the `Table` endpoints directly (see below for setup).

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
          {ExAirtable.Supervisor, [MyApp.MyAirtable, MyApp.MyOtherAirtable, ...]},

          # ...
        ]

        opts = [strategy: :one_for_one, name: PhoenixCms.Supervisor]
        Supervisor.start_link(children, opts)
      end

      # ...
    end

## Examples + Playing Around

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
