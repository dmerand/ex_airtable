defmodule ExAirtable.SupervisorTest do
  use ExUnit.Case, async: true
  import ExUnit.CaptureLog

  @table_module ExAirtable.MockTable

  test "does it even work" do
    assert capture_log(fn ->
      ExAirtable.Supervisor.start_link([@table_module])
    end) =~ "Synching ExAirtable.MockTable"
  end
end
