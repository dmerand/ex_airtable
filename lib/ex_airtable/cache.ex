defmodule ExAirtable.Cache do
  @moduledoc """
  A caching server for an `ExAirtable.Table`. Given a `Table` when initialized, it will automatically spawn synchronization processes and provide an in-memory data store that stays in sync with the external Airtable table/base.

  ## Examples
      
      iex> Cache.retrieve(MyAirtableTable, "rec1234")
      %Airtable.Record{}

      iex> Cache.list(MyAirtableTable)
      %Airtable.List{records: [%Airtable.Record{}, ...]}
  """

  alias ExAirtable.{Airtable, Cache}
  use GenServer

  defstruct table_module: nil, sync_ref: nil, sync_rate: nil

  @typedoc """
  A struct that contains the state for a `Cache`.
  """
  @type t :: %__MODULE__{
    table_module: module(),
    sync_ref: pid(),
    sync_rate: integer()
  }

  ############
  # PUBLIC API
  ############
  
  @doc """
  Given an `ExAirtable.Table` module, get all `%Airtable.Record{}`s in that cache's table as an `%Airtable.List{}`.
  """
  def list(table_module) do
    table_module
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
  Given an `ExAirtable.Table` module and a string key, get the %Record{} in that cache with the matching key.
  """
  def retrieve(table_module, key) when is_binary(key) do
    table_module
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
  Given an `ExAirtable.Table` module, an ID, and a corresponding item to match that ID, store it in the cache.
  """
  def set(table_module, id, item) when is_binary(id) do
    GenServer.cast(table_module, {:set, id, item})
  end

  @doc """
  Replace an entire cache with a new set of `%Airtable.Record{}`s.
  """
  def set_all(table_module, %Airtable.List{} = list) do
    GenServer.cast(table_module, {:set_all, list})
  end

  @doc """
  Returns a valid ETS table name for a give `ExAirtable.Table` module.
  """
  def table_for(table_module) do
    String.to_atom(table_module.base.id <> table_module.name())
  end

  ###########
  # GENSERVER 
  ###########

  @doc """
  Start a caching server.

  Valid options (in the `opts` field) include:

  - `table_module` (required) - The module name of the `ExAirtable.Table` module you're caching. If this is not included, the link will raise an error.
  - `sync_rate` - How often (in ms) to refresh data from Airtable.
  - `skip_sync` (boolean) - If you don't want to run the sync server for whatever reason (typically testing)
  """
  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: Keyword.fetch!(opts, :table_module))
  end

  @doc """
  Just for GenServer config, doesn't need to be run by hand
  """
  def child_spec(opts) do
    %{
      id: Keyword.fetch!(opts, :table_module),
      start: {__MODULE__, :start_link, [opts]},
      type: :worker,
      restart: :permanent,
      shutdown: 500
    }
  end

  @impl GenServer
  @doc """
  Initialize the caching server. This is not meant to be called manually, but will be handle when `start_link/2` is called.

  See `start_link/1` for options.
  """
  def init(opts) do
    table_module = Keyword.fetch!(opts, :table_module)
    :ets.new(table_for(table_module), [:ordered_set, :protected, :named_table])

    state = %__MODULE__{
      table_module: table_module, 
      sync_rate: Keyword.get(opts, :sync_rate, :timer.seconds(30))
    }
    state = %{state | sync_ref: case Keyword.get(opts, :skip_sync) do
        true -> nil
        _ -> initialize_synchronizer(state)
    end}

    {:ok, state}
  end

  @impl GenServer
  def handle_cast({:set, id, item}, %{table_module: table_module} = state) do
    table_module
    |> Cache.table_for()
    |> :ets.insert({id, item})

    {:noreply, state}
  end

  def handle_cast({:set_all, %Airtable.List{records: records}}, %{table_module: table_module} = state) do
    Enum.each(records, &:ets.insert(Cache.table_for(table_module), {&1.id, &1}))

    {:noreply, state}
  end

  @impl GenServer
  def handle_info( {:DOWN, ref, :process, _object, _reason}, %{sync_ref: ref} = state) do
    {:noreply, %{state | sync_ref: initialize_synchronizer(state)}}
  end

  def handle_info({:EXIT, _, _}, state) do
    {:noreply, state}
  end

  defp initialize_synchronizer(state) do
    {:ok, pid} = Cache.Synchronizer.start_link(
      table_module: state.table_module, 
      sync_rate: state.sync_rate
    )
    Process.monitor(pid)
  end
end
