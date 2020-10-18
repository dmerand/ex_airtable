defmodule ExAirtable.Supervisor do
  use Supervisor

  alias ExAirtable.{BaseQueue, RateLimiter, TableCache}

  def start_link(table_modules) when is_list(table_modules) do
    Supervisor.start_link(__MODULE__, table_modules, name: __MODULE__)
  end

  @doc """
  Given a list of table module names, where each module has implemented the `ExAirtable.Table` behaviour...

  1. Start a global RateLimiter
  2. For each unique Airtable base ID (from the passed table module configuration), start a BaseQueue
  3. For each passed table module, start a TableCache, which will in turn start a TableSynchronizer
  """
  @impl true
  def init(table_modules) do
    table_caches = Enum.map(table_modules, fn module ->
      {TableCache, table_module: module}
    end)

    base_queues = Enum.reduce(table_modules, %{}, fn module, acc ->
      base = apply(module, :base, [])
      modules = Map.get(acc, base, [])
      Map.put(acc, base, [module | modules])
    end)
    |> Map.values
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
