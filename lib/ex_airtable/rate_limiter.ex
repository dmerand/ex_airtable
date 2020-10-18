defmodule ExAirtable.RateLimiter do
  use GenStage

  alias ExAirtable.BaseQueue
  alias ExAirtable.RateLimiter.{Producer, Request}

  def handle_subscribe(:producer, _opts, from, producers) do
    producers = Map.put(producers, from, %Producer{})
    producers = ask_and_schedule(producers, from)

    {:manual, producers}
  end

  def handle_cancel(_, from, producers) do
    {:noreply, [], Map.delete(producers, from)}
  end

  def handle_events(events, _from, producers) do
    Enum.each(events, &Request.run/1)

    {:noreply, [], producers}
  end

  def handle_info({:ask, from}, producers) do
    {:noreply, [], ask_and_schedule(producers, from)}
  end

  @doc """
  Pass a list of valid module names where the given modules have implemented the `ExAirtable.Table` behaviour.

  Internal state is a map of `%Producer{}` structs where the key is the module name of the producer.
  """
  def init(table_modules) do
    subscriptions = Enum.map(table_modules, &BaseQueue.id/1)
    {:consumer, %{}, subscribe_to: subscriptions}
  end

  def start_link(table_modules) do
    GenStage.start_link(__MODULE__, table_modules, name: __MODULE__)
  end

  defp ask_and_schedule(producers, from) do
    case producers do
      %{^from => %Producer{} = producer} ->
        GenStage.ask(from, producer.max_demand)
        Process.send_after(self(), {:ask, from}, producer.interval)
        producers
      %{} ->
        producers
    end
  end
end
