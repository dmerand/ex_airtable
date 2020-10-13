defmodule ExAirtable.BaseQueue do
  @moduledoc """
  The purpose of the BaseQueue is to serve as a "Producer" for the RateLimiter. Requests that are meant to go to Airtable are sent to the appropriate BaseQueue (one per base, shared among all Tables), and put in line for the RateLimiter to execute as it's able.

  Note that the request buffer is a MapSet - meaning that duplicate requests will be ignored.
  """

  use GenStage

  alias ExAirtable.RateLimiter.Request

  defstruct tables: [],
            requests: MapSet.new()

  @typedoc """
  Each BaseQueue stores a list of tables and all pending requests against that base, as well as the GenServer ID of the BaseQueue.
  """
  @type t :: %__MODULE__{
    tables: [module()],
    requests: MapSet.t(Request.t())
  }

  #
  # PUBLIC API
  #

  @doc """
  Retrieve the BaseQueue (GenServer) ID for a given table.
  """
  def id(table) do
    "BaseQueue-" <> table.base().id
    |> String.to_atom()
  end

  @doc """
  Add a request to the request buffer.

  Note that the request buffer is a MapSet - meaning that (exact) duplicate requests will be ignored.
  """
  def request(table, %Request{} = request) do
    GenServer.cast(id(table), {:add_request, request})
  end

  #
  # GENSERVER / GENSTAGE API
  # 

  def handle_cast({:add_request, %Request{} = request}, state) do
    {:noreply, [], %{state | requests: MapSet.put(state.requests, request)}}
  end

  def handle_demand(demand, state) when demand > 0 do
    {events, remainder} = 
      state.requests
      |> MapSet.to_list()
      |> Enum.split(demand)

    {:noreply, events, %{state | requests: MapSet.new(remainder)}}
  end

  def init(tables) when is_list(tables) do
    {:producer, %__MODULE__{tables: tables}}
  end

  def start_link(tables) do
    # We're assuming that all passed tables have the same base!
    first_table = Enum.at(tables, 0)

    GenStage.start_link(__MODULE__, tables, name: id(first_table))
  end
end
