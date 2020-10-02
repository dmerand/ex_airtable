defmodule ExAirtable.CacheTest do
  use ExUnit.Case, async: true
  alias ExAirtable.Airtable.{List, Record}
  alias ExAirtable.Cache
  alias ExAirtable.Example.EnvTable

  @table_module ExAirtable.MockTable

  setup do
    start_supervised!({Cache, table_module: @table_module, skip_sync: true})
    %{}
  end

  test "basics" do
    table_name = Cache.table_for(@table_module)
    assert is_atom(table_name)
    assert Atom.to_string(table_name) =~ @table_module.base.id
  end

  test "set + retrieve by ID" do
    Cache.set(@table_module, "cool", "beans")
    Process.sleep(10) # Give it a moment, since it's a cast
    assert {:ok, "beans"} = Cache.retrieve(@table_module, "cool")
  end

  test "multiple cache servers don't overlap" do
    Cache.start_link(table_module: EnvTable, skip_sync: true) 

    Cache.set(@table_module, "new", "item")
    Cache.set(EnvTable, "new", "other_item")
    Process.sleep(10) # Give it a moment, since it's a cast
    assert {:ok, "item"} = Cache.retrieve(@table_module, "new")
    assert {:ok, "other_item"} = Cache.retrieve(EnvTable, "new")
  end

  test "set_all + list" do
    list = %List{records: [
      %Record{id: 1, fields: %{cool: "beans"}},
      %Record{id: 2, fields: %{neato: "mosquito"}},
    ]}
    Cache.set_all(@table_module, list)
    Process.sleep(10) # Give it a moment, since it's a cast
    assert {:ok, %List{} = list} = Cache.list(@table_module)
  end
end
