defmodule ExAirtable.BaseQueueTest do
  use ExUnit.Case, async: true

  alias ExAirtable.BaseQueue
  alias ExAirtable.RateLimiter.Request

  @table_module ExAirtable.MockTable

  setup do
    pid = start_supervised!({BaseQueue, [@table_module]})
    gen_stage = :sys.get_state(pid)
    %{gen_stage: gen_stage, pid: pid}
  end

  test "ID generation" do
    id = :"BaseQueue-Mock ID" 
    assert ^id = BaseQueue.id(@table_module)
  end

  test "Initial table state", %{gen_stage: gen_stage} do
    assert [ExAirtable.MockTable] = gen_stage.state.tables
  end

  test "Request buffer", %{pid: pid} do
    request = Request.create(
      {String, :to_atom, ["has_callback"]}, 
      {Kernel, :send, [self()]}
    )
    BaseQueue.request(@table_module, request)
		# Sleeping because it's a cast.
    Process.sleep(10)
    gen_stage = :sys.get_state(pid)
		assert MapSet.member?(gen_stage.state.requests, request)
		assert 1 = Enum.count(gen_stage.state.requests)

		# Test duplicate
    BaseQueue.request(@table_module, request)
    Process.sleep(10)
    gen_stage = :sys.get_state(pid)
		assert 1 = Enum.count(gen_stage.state.requests)
  end
end
