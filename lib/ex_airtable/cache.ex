defmodule ExAirtable.Cache do
  alias ExAirtable.Cache

  defmacro __using__(_) do
    quote do
      use GenServer

      @impl GenServer
      def init(module) do
        module
        |> Cache.table_for() 
        |> :ets.new([:ordered_set, :protected, :named_table])

        {:ok, %{module: module}}
      end

      def child_spec(opts) do
        %{
          id: __MODULE__,
          start: {__MODULE__, :start_link, [opts]},
          type: :worker,
          restart: :permanent,
          shutdown: 500
        }
      end

      def start_link(module) do
        GenServer.start_link(__MODULE__, module, name: __MODULE__)
      end

      @impl GenServer
      def handle_call(:get_module, _from, %{module: module} = state) do
        {:reply, module, state}
      end

      @impl GenServer
      def handle_cast({:set_all, items}, %{module: module} = state)
          when is_list(items) do
        Enum.each(items, &:ets.insert(Cache.table_for(module), {&1.id, &1}))

        {:noreply, state}
      end

      def handle_cast({:set, id, item}, %{module: module} = state) do
        module
        |> Cache.table_for()
        |> :ets.insert({id, item})

        {:noreply, state}
      end
    end
  end

  def get_all(cache) do
    cache
    |> module_for()
    |> table_for()
    |> :ets.tab2list()
    |> case do
      values when values != [] ->
        {:ok, Enum.map(values, &elem(&1, 1))}

      _ ->
        {:error, :not_found}
    end
  end

  def get(cache, key) do
    cache
    |> module_for()
    |> table_for()
    |> :ets.lookup(key)
    |> case do
      [{^key, value} | _] ->
        {:ok, value}

      _ ->
        {:error, :not_found}
    end
  end

  def module_for(cache) do
    GenServer.call(cache, :get_module)
  end

  def table_for(module) do
    String.to_atom(module.name)
  end

  def set(cache, id, item), do: GenServer.cast(cache, {:set, id, item})

  def set_all(cache, items), do: GenServer.cast(cache, {:set_all, items})
end
