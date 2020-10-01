# ExAirtable

A decent way to get abstraction and caching around Airtable API calls in Elixir

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
