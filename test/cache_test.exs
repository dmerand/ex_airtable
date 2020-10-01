defmodule ExAirtable.ExternalTableCache do
  use ExAirtable.Cache
end

defmodule ExAirtable.CacheTest do
  use ExUnit.Case, async: true
  alias ExAirtable.Airtable.Record
  alias ExAirtable.{Cache, ExternalTable}
  alias ExAirtable.ExternalTableCache, as: ETC

  setup do
    cache = start_supervised!({ETC, ExternalTable})
    %{cache: cache}
  end

  test "basics" do
    assert ExAirtable.ExternalTable = Cache.module_for(ETC)
  end

  test "set + get by ID", %{cache: cache} do
    assert Cache.set(cache, "cool", "beans")
    assert {:ok, "beans"} = Cache.get(cache, "cool")
  end

  test "set_all + get_all", %{cache: cache} do
    items = [
      %Record{id: 1, fields: %{cool: "beans"}},
      %Record{id: 2, fields: %{neato: "mosquito"}},
    ]
    assert Cache.set_all(cache, items)
    assert {:ok, items} = Cache.get_all(cache)
  end
end
