defmodule ExAirtable.RateLimiterTest do
  use ExUnit.Case

  alias ExAirtable.{BaseQueue, RateLimiter}
  alias ExAirtable.RateLimiter.{Job, Request}

  @table_module ExAirtable.MockTable

  setup do
    rate_limiter = start_supervised!({RateLimiter, []})
    base_queue = start_supervised!({BaseQueue, [@table_module]})
    %{base_queue: base_queue, rate_limiter: rate_limiter}
  end

  test "does it even work", %{base_queue: base_queue, rate_limiter: rate_limiter} do
    assert base_queue
    assert rate_limiter
  end

  test "requests flow through", %{base_queue: base_queue} do
    request = %Request{
      job: %Job{module: String, function: :to_atom, arguments: ["requests_flow"]},
      callback: %Job{module: Kernel, function: :send, arguments: [self()]}
    }

    BaseQueue.request(@table_module, request)
    assert MapSet.member?(:sys.get_state(base_queue).state.requests, request)

    GenStage.sync_subscribe(RateLimiter, to: BaseQueue.id(@table_module))
    refute MapSet.member?(:sys.get_state(base_queue).state.requests, request)
    assert_received :requests_flow
  end

  @tag :external_api # because it's slow, and *technically* external :/
  test "only pulls 5 requests per wave", %{base_queue: base_queue} do
    Enum.each(1..6, fn i ->
      request = %Request{
        job: %Job{module: String, function: :to_atom, arguments: ["request_#{i}"]},
        callback: %Job{module: Kernel, function: :send, arguments: [self()]}
      }

      BaseQueue.request(@table_module, request)
    end)

    GenStage.sync_subscribe(RateLimiter, to: BaseQueue.id(@table_module))
    assert 1 = Enum.count(:sys.get_state(base_queue).state.requests)
    assert_received :request_1
    refute_received :request_6

    Process.sleep(1500)
    assert 0 = Enum.count(:sys.get_state(base_queue).state.requests)
    assert_received :request_6
  end
end
