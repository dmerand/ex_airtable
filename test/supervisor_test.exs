defmodule ExAirtable.SupervisorTest do
  use ExUnit.Case, async: true

  @table_module ExAirtable.MockTable

  test "does it even work" do
    assert {:ok, pid} = ExAirtable.Supervisor.start_link([@table_module])
  end
end
