defmodule ExAirtable.TableCacheTest do
  use ExUnit.Case, async: true
  alias ExAirtable.Airtable.{List, Record}
  alias ExAirtable.TableCache
  alias ExAirtable.Example.EnvTable

  @table_module ExAirtable.MockTable

  setup do
    start_supervised!({TableCache, table_module: @table_module, skip_sync: true})
    %{}
  end

  test "basics" do
    table_name = TableCache.table_for(@table_module)
    assert is_atom(table_name)
    assert Atom.to_string(table_name) =~ @table_module.base.id
  end

  test "set + retrieve by ID" do
    TableCache.set(@table_module, "cool", "beans")
    # Give it a moment, since it's a cast
    Process.sleep(20)
    assert {:ok, "beans"} = TableCache.retrieve(@table_module, "cool")
  end

  test "multiple Tablecache servers don't overlap" do
    TableCache.start_link(table_module: EnvTable, skip_sync: true)

    TableCache.set(@table_module, "new", "item")
    TableCache.set(EnvTable, "new", "other_item")
    Process.sleep(20)
    assert {:ok, "item"} = TableCache.retrieve(@table_module, "new")
    assert {:ok, "other_item"} = TableCache.retrieve(EnvTable, "new")
  end

  test "set_all + list" do
    list = %List{
      records: [
        %Record{id: "1", fields: %{cool: "beans"}},
        %Record{id: "2", fields: %{neato: "mosquito"}}
      ]
    }

    TableCache.set_all(@table_module, list)
    Process.sleep(20)
    assert {:ok, %List{} = list} = TableCache.list(@table_module)
  end

  test "delete by ID" do
    TableCache.set(@table_module, "cool", "beans")
    Process.sleep(20)
    assert {:ok, "beans"} = TableCache.retrieve(@table_module, "cool")
    TableCache.delete(@table_module, %{"id" => "cool"})
    Process.sleep(100)
    assert {:error, :not_found} = TableCache.retrieve(@table_module, "cool")
  end

  test "update existing record" do
    record = %Record{id: "1", fields: %{update_existing: false}}
    TableCache.set(@table_module, record.id, record)
    updated_record = %{record | fields: %{update_existing: true}}

    TableCache.update(@table_module, %List{records: [updated_record]})
    # Give it a moment, since it's a cast
    Process.sleep(20)
    assert {:ok, ^updated_record} = TableCache.retrieve(@table_module, record.id)
  end

  test "upsert" do
    record = %Record{id: "1", fields: %{upsert: true}}
    TableCache.update(@table_module, %List{records: [record]})
    # Give it a moment, since it's a cast
    Process.sleep(20)
    assert {:ok, ^record} = TableCache.retrieve(@table_module, record.id)
  end
end
