defmodule ExAirtable.RateLimiterTest do
  use ExUnit.Case, async: true

  alias ExAirtable.{BaseQueue, RateLimiter}
  alias ExAirtable.RateLimiter.Request

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

  test "requests flow to rate limiter on sync_subscribe", %{base_queue: base_queue} do
    request = Request.create(
      {String, :to_atom, ["requests_flow"]}, 
      {Kernel, :send, [self()]}
    )

    BaseQueue.request(@table_module, request)
    assert MapSet.member?(:sys.get_state(base_queue).state.requests, request)

    GenStage.sync_subscribe(RateLimiter, to: BaseQueue.id(@table_module))
    refute MapSet.member?(:sys.get_state(base_queue).state.requests, request)
    assert_receive :requests_flow, 100
  end

  test "automatic subscription via passed table modules" do
    request = Request.create(
      {String, :to_atom, ["auto_subscription"]}, 
      {Kernel, :send, [self()]}
    )

    BaseQueue.request(@table_module, request)
    GenStage.start_link(RateLimiter, [@table_module])
    assert_receive :auto_subscription, 100
  end


  @tag :external_api # because it's slow, and *technically* external :/
  test "only pulls 5 requests per wave", %{base_queue: base_queue} do
    Enum.each(1..15, fn i ->
      request = Request.create(
        {String, :to_atom, ["request_#{i}"]}, 
        {Kernel, :send, [self()]}
      )
      BaseQueue.request(@table_module, request)
    end)

    GenStage.sync_subscribe(RateLimiter, to: BaseQueue.id(@table_module))

    Process.sleep(100)
    assert 10 = Enum.count(:sys.get_state(base_queue).state.requests)
    Process.sleep(1000)
    assert 5 = Enum.count(:sys.get_state(base_queue).state.requests)
    Process.sleep(1000)
    assert 0 = Enum.count(:sys.get_state(base_queue).state.requests)
  end
end
