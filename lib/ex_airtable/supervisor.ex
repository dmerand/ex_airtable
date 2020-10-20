defmodule ExAirtable.Supervisor do
  @moduledoc """
  This is the "master control" that takes care of rate-limiting and caching for all of your Tables. See the `ExAirtable` module and `start_link/2` for details about initialization.
  """

  use Supervisor
  alias ExAirtable.{BaseQueue, RateLimiter, TableCache}

  @doc """
  Given a list of table module names, where each module has implemented the `ExAirtable.Table` behaviour...

  1. Start a global RateLimiter
  2. For each unique Airtable base ID (from the passed table module configuration), start a BaseQueue
  3. For each passed table module, start a TableCache, which will in turn start a TableSynchronizer

  Given options will be passed to sub-processes. Valid options are:

  - `:delete_on_refresh` (boolean) - By default, this is `true`, so that if a record is deleted in Airtable, it will be deleted in your cache. If you don't need this behaviour, setting it to `false` will reduce churn on your ETS cache (because the cache won't be cleared out on each refresh).
  - `:sync_rate` (integer) - amount of time in milliseconds between attempts to refresh table data from the API. Each table that you define will re-synchronize at this rate.
  """
  def start_link(table_modules, opts \\ []) when is_list(table_modules) do
    Supervisor.start_link(__MODULE__, {table_modules, opts}, name: __MODULE__)
  end

  @impl true
  def init({table_modules, opts}) do
    table_caches =
      Enum.map(table_modules, fn module ->
        {TableCache, Keyword.put(opts, :table_module, module)}
      end)

    base_queues =
      Enum.reduce(table_modules, %{}, fn module, acc ->
        base = apply(module, :base, [])
        modules = Map.get(acc, base, [])
        Map.put(acc, base, [module | modules])
      end)
      |> Map.values()
      |> Enum.map(fn table_modules ->
        {BaseQueue, table_modules}
      end)

    children =
      table_caches ++
        base_queues ++
        [{RateLimiter, table_modules}]

    Supervisor.init(children, strategy: :one_for_one)
  end
end
