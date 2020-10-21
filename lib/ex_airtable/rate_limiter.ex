defmodule ExAirtable.RateLimiter do
  @moduledoc """
  The RateLimiter ensures that no requests go to Airtable fast enough to trigger API rate-limiting.

  Requests will be handled immediately until more than 5 happen, at which point they go onto a queue which flushes every second. This ensures that no more than 5 requests per second will ever be sent to Airtable.

  There is one `ExAirtable.RateLimiter.BaseQueue` per base to track requests, since Airtable does rate-limiting per-base.
  """

  use GenServer
  alias ExAirtable.RateLimiter.{BaseQueue, Request}

  @doc """
  Add a request to the request buffer for a given table.

  Note that the request buffer is a MapSet - meaning that (exact) duplicate requests will be ignored.
  """
  def request(table_module, %Request{} = request) do
    GenServer.cast(__MODULE__, {:add_request, table_module.base().id, request})
  end

  @impl GenServer
  @doc false
  def handle_cast({:add_request, base_id, request}, base_queues) do
    base_queue = Map.get(base_queues, base_id)

    if can_be_synchronous(base_queue) do
      Request.run(request)

      updated_queues =
        Map.put(base_queues, base_id, 
          %{base_queue | in_progress: base_queue.in_progress + 1}
        )

      {:noreply, updated_queues}
    else
      updated_queues =
        Map.put(base_queues, base_id, 
          %{base_queue | requests: MapSet.put(base_queue.requests, request)}
        )

      {:noreply, updated_queues}
    end
  end

  @impl GenServer
  @doc false
  def handle_info({:run_requests, base_id}, base_queues) do
    base_queue = Map.get(base_queues, base_id)

    {requests_to_run, remainder} =
      base_queue
      |> Map.get(:requests)
      |> Enum.sort_by(& &1.created)
      |> Enum.split(base_queue.max_demand - base_queue.in_progress)

    Enum.map(requests_to_run, & Task.async(fn -> Request.run(&1) end))
    |> Enum.each(&Task.await/1)

    updated_queues =
      Map.put(base_queues, base_id, %{base_queue | 
        requests: MapSet.new(remainder),
        in_progress: 0
      })

    schedule(updated_queues, base_id)

    {:noreply, updated_queues}
  end

  @impl GenServer
  @doc false
  def init(table_modules) do
    base_queues =
      Enum.reduce(table_modules, %{}, fn table_module, acc ->
        Map.put(acc, table_module.base().id, %BaseQueue{})
      end)

    base_queues
    |> Map.keys()
    |> Enum.each(&schedule(base_queues, &1))

    {:ok, base_queues}
  end

  @doc """
  Pass a list of valid module names where the given modules have implemented the `ExAirtable.Table` behaviour.

  Internal state is a map of `%BaseQueue{}` structs where the key is the base ID.
  """
  def start_link(table_modules) do
    GenServer.start_link(__MODULE__, table_modules, name: __MODULE__)
  end

  defp can_be_synchronous(base_queue) do
    base_queue.in_progress < base_queue.max_demand
  end

  defp schedule(base_queues, base_id) do
    with base_queue <- Map.get(base_queues, base_id) do
      Process.send_after(
        __MODULE__,
        {:run_requests, base_id},
        base_queue.interval
      )
    end
  end
end
