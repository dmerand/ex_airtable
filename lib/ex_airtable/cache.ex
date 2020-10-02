defmodule ExAirtable.Cache do
  alias ExAirtable.{Airtable, Cache}

  defstruct module: nil, sync_ref: nil, sync_rate: nil

  @typedoc """
  A struct that contains the state for a `Cache`
  """
  @type t :: %__MODULE__{
    module: module(),
    sync_ref: pid(),
    sync_rate: integer()
  }

  defmacro __using__(_) do
    quote do
      use GenServer

      def child_spec(opts) do
        %{
          id: __MODULE__,
          start: {__MODULE__, :start_link, [opts]},
          type: :worker,
          restart: :permanent,
          shutdown: 500
        }
      end

      @impl GenServer
      @doc """
      Initiliaze the caching server. This is not meant to be called manually, but will be handle when `start_link/2` is called.
      """
      def init({module, opts}) do
        module
        |> Cache.table_for() 
        |> :ets.new([:ordered_set, :protected, :named_table])

        {:ok, pid} = Cache.Synchronizer.start_link(
          cache: __MODULE__, 
          sync_rate: Keyword.get(opts, :sync_rate, :timer.seconds(30))
        )
        ref = Process.monitor(pid)

        state = %unquote(__MODULE__){module: module, sync_ref: ref}
        {:ok, state}
      end

      @doc """
      Start a caching server. 

      Valid options (in the `opts` field) include:

      - `sync_rate` - How often (in ms) to refresh data from Airtable.
      """
      def start_link(module, opts \\ []) do
        GenServer.start_link(__MODULE__, {module, opts}, name: __MODULE__)
      end

      @impl GenServer
      def handle_call(:get_module, _from, %{module: module} = state) do
        {:reply, module, state}
      end

      @impl GenServer
      def handle_cast({:set_all, %Airtable.List{records: records}}, %{module: module} = state) do
        Enum.each(records, &:ets.insert(Cache.table_for(module), {&1.id, &1}))

        {:noreply, state}
      end

      def handle_cast({:set, id, item}, %{module: module} = state) do
        module
        |> Cache.table_for()
        |> :ets.insert({id, item})

        {:noreply, state}
      end

			@impl GenServer
			def handle_info(
						{:DOWN, ref, :process, _object, _reason},
						%{synchronizer_ref: ref} = state
					) do
        {:ok, pid} = Cache.Synchronizer.start_link(cache: __MODULE__)
				ref = Process.monitor(pid)

				{:noreply, %{state | sync_ref: ref}}
			end

			def handle_info({:EXIT, _, _}, state) do
				{:noreply, state}
			end
    end
  end

  @doc """
  Given an `ExAirtable.Cache` module, get all `%Airtable.Record{}`s in that cache's table as an `%Airtable.List{}`.
  """
  def get_all(cache) do
    cache
    |> module_for()
    |> table_for()
    |> :ets.tab2list()
    |> case do
      values when values != [] ->
        {:ok, %Airtable.List{
          records: Enum.map(values, &elem(&1, 1))
        }}

      _ ->
        {:error, :not_found}
    end
  end

  @doc """
  Given an `ExAirtable.Cache` module and a key, get the %Record{} in that cache with the matching key.
  """
  def get(cache, key) when is_binary(key) do
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

  @doc """
  Returns the name of the associated `ExAirtable.Table` module for the given `ExAirtable.Cache` module.
  """
  def module_for(cache) do
    GenServer.call(cache, :get_module)
  end

  @doc """
  Returns a valid ETS table name for a give `ExAirtable.Table` module.
  """
  def table_for(module) do
    String.to_atom(module.name())
  end

  @doc """
  Given an `ExAirtable.Cache` module, an ID, and a corresponding item to match that ID, store it in the cache.
  """
  def set(cache, id, item) when is_binary(id) do
    GenServer.cast(cache, {:set, id, item})
  end

  @doc """
  Replace an entire cache with a new set of `%Airtable.Record{}`s.
  """
  def set_all(cache, %Airtable.List{} = list) do
    GenServer.cast(cache, {:set_all, list})
  end
end
