defmodule ExAirtable.RateLimiterTest do
  use ExUnit.Case, async: true

  alias ExAirtable.RateLimiter
  alias ExAirtable.RateLimiter.Request

  @process_delay 100
  @table_module ExAirtable.MockTable

  setup do
    {:ok, pid} = start_supervised({RateLimiter, [@table_module]})
    %{pid: pid}
  end

  test "does it even work", %{pid: pid} do
    assert pid
  end

  test "request goes through" do
    request =
      Request.create(
        {String, :to_atom, ["goes_through"]},
        {Kernel, :send, [self()]}
      )

    RateLimiter.request(@table_module, request)
    assert_receive :goes_through, @process_delay
  end

  test "overflow goes into queue", %{pid: pid} do
    refute Enum.count(get_base_queue(pid).requests) > 0

    Enum.each(1..15, fn i ->
      request =
        Request.create(
          {String, :to_atom, ["request_#{i}"]},
          {Kernel, :send, [self()]}
        )

      RateLimiter.request(@table_module, request)
    end)

    assert Enum.count(get_base_queue(pid).requests) > 0

    Enum.each(1..15, fn i ->
      atom = :"request_#{i}"
      assert_receive ^atom, 2000
    end)
  end

  def get_base_queue(pid) do
    case :sys.get_state(pid) do
      %{} = state ->
        Map.get(state, @table_module.base().id)
      _ -> 
      %{}
    end
  end
end
