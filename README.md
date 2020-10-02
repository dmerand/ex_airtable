# ExAirtable

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
          {ExAirtable.Cache, table_module: MyApp.MyAirtable},
          {ExAirtable.Cache, table_module: MyApp.MyOtherAirtable},

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
    iex> EnvTable.list
    %ExAirtable.Airtable.List{records: [%Record{}, %Record{}, ...]}

    # to retrieve data directly from Airtable's API...
    iex> EnvTable.retrieve("rec12345")
    %ExAirtable.Airtable.Record{}

    # to start a caching server for your table...
    iex> ExAirtable.Cache.start_link(table_module: EnvTable, sync_rate: :timer.seconds(5))

    # to get all records from the cache (without hitting the Airtable API)
    iex> Cache.get_all(EnvTable)
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
