# ExAirtable

Provides an interface to query Airtable bases/tables, and an optional server to cache the results of a table into memory for faster access and to avoid Airtable API access limitations.

For all of the details, check out the latest project documentation here: <https://hexdocs.pm/ex_airtable/ExAirtable.html>.

If you're interested in using ExAirtable in a Phoenix project and/or with Ecto schema validation, you may want to check out <https://hex.pm/packages/ex_airtable_phoenix>

## Installation

The package can be installed by adding `ex_airtable` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:ex_airtable, "~> 0.2.0"}
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
