defmodule ExAirtable.Example.EnvCache do
  @moduledoc """
  This is useful for playing around in the console - it'll load up a table based on whatever you have in your config. Try `make console` to quickly load the defaults.

  In your console, try running `{:ok, pid} = EnvCache.start_link(EnvTable)`
  """
  use ExAirtable.Cache
end
