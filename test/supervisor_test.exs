defmodule ExAirtable.SupervisorTest do
  use ExUnit.Case, async: true

  alias ExAirtable.Airtable
  alias ExAirtable.{FauxTable, MockTable}

  test "does it even work" do
    assert {:ok, _pid} = start_supervised({ExAirtable.Supervisor, [MockTable]})
    assert {:ok, %Airtable.List{}} = ExAirtable.list(MockTable)
  end

  test "multiple tables" do
    assert {:ok, _pid} = start_supervised({ExAirtable.Supervisor, [MockTable, FauxTable]})
    assert {:ok, %Airtable.List{}} = ExAirtable.list(MockTable)
    assert {:ok, %Airtable.List{}} = ExAirtable.list(FauxTable)
  end
end
