defmodule ExAirtable.Supervisor do
  @moduledoc """
  This is the "master control" that takes care of rate-limiting and caching for all of your Tables. 

  See the `ExAirtable` module and `start_link/2` for details about initialization.
  """

  use Supervisor
  alias ExAirtable.{RateLimiter, TableCache}

  @doc """
  Given a list of table module names, where each module has implemented the `ExAirtable.Table` behaviour...

  1. Start a global RateLimiter.
  2. For each passed table module, start a TableCache, which will in turn start a TableSynchronizer.

  Given options will be passed to sub-processes. Valid options are:

  - `:sync_rate` (integer) - amount of time in milliseconds between attempts to refresh table data from the API. Each table that you define will re-synchronize at this rate.
  """
  def start_link(table_modules) when is_list(table_modules) do
    Supervisor.start_link(__MODULE__, {table_modules, []}, name: __MODULE__)
  end

  def start_link({table_modules, opts}) when is_list(table_modules) do
    Supervisor.start_link(__MODULE__, {table_modules, opts}, name: __MODULE__)
  end

  @impl true
  def init({table_modules, opts}) do
    table_caches =
      Enum.map(table_modules, fn module ->
        {TableCache, Keyword.put(opts, :table_module, module)}
      end)

    children = [{RateLimiter, table_modules}] ++ table_caches

    Supervisor.init(children, strategy: :one_for_one)
  end
end
