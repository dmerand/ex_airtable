defmodule ExAirtable.TableSynchronizer do
  @moduledoc """
  Run scheduled synchronization of an `ExAirtable.TableCache` against the relevant Airtable base. This will be automatically spawned and linked to an `ExAirtable.TableCache` when `start_link/2` is run for that cache.
  """

  defstruct sync_rate: nil, table_module: nil

  @typedoc """
  A struct that contains the state for a `TableSynchronizer`
  """
  @type t :: %__MODULE__{
    table_module: module(),
    sync_rate: integer()
  }

  use GenServer
  require Logger
  alias ExAirtable.Cache

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts)
  end

  @impl GenServer
  def init(opts) do
    state = %__MODULE__{
      sync_rate: Keyword.fetch!(opts, :sync_rate),
      table_module: Keyword.fetch!(opts, :table_module)
    }

    send(self(), :sync)

    {:ok, state}
  end

  @impl GenServer
  def handle_info(:sync, %{table_module: table_module} = state) do
    Logger.debug "Synching #{inspect table_module}..."
    TableCache.set_all(table_module, fetch(state))
    schedule(state)

    {:noreply, state}
  end

  defp fetch(state) do
    apply(state.table_module, :list, [])
  end

  defp schedule(state) do
    Process.send_after(self(), :sync, state.sync_rate)
  end
end
