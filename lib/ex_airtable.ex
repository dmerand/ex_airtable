defmodule ExAirtable do
  @moduledoc """
  Provides an interface to query Airtable bases/tables, and an optional server to cache the results of a table into memory for faster access and to avoid API access limitations.

  Generally, you'll need to do two things:

  1. Add a `%ExAirtable.Config.Base` into your application configuration for each Airtable base that you intend to reference.
  2. For each table within a base that you intend to query, define a module in your codebase that implements the `ExAirtable.Table` behaviour (by running `use ExAirtable.Table` and implementing the `table_name()` callback).

  If you wish to run a local caching server, you'll need to take the third step of defining one module implementing the `ExAirtable.Cache` behaviour for each `Table` you wish to cache.

  ## Examples
  The codebase includes an example `Table` and `Cache` (`ExAirtable.Example.EnvTable` and `ExAirtable.Example.EnvCache`) that you can use to play around and get an idea of how the system works. 

  These modules work use environment variables as their configuration. The included `Makefile` provides some quick command-line tools to run tests and a console with those environment variables pre-loaded. Simply edit the relevant environment variables in `Makefile` to point to a valid base/table name, and you'll be able to interact directly like this:

      # first, run `make console`, then...
      iex> EnvTable.list
      %ExAirtable.Airtable.List{records: [%Record{}, %Record{}, ...]}

      iex> EnvTable.retrieve("rec12345")
      %ExAirtable.Airtable.Record{}

      iex> {:ok, pid} = EnvCache.start_link()
      iex> Cache.get_all(EnvCache)
  """
end
