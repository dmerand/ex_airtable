defmodule ExAirtable.CacheTest do
  use ExUnit.Case, async: true
  alias ExAirtable.Cache
  alias ExAirtable.Airtable.{List, Record}
  alias ExAirtable.Example.{EnvCache, EnvTable}

  setup do
    cache = start_supervised!({EnvCache, EnvTable})
    %{cache: cache}
  end

  test "basics" do
    assert EnvTable = Cache.module_for(EnvCache)
  end

  test "set + get by ID", %{cache: cache} do
    assert Cache.set(cache, "cool", "beans")
    assert {:ok, "beans"} = Cache.get(cache, "cool")
  end

  test "set_all + get_all", %{cache: cache} do
    list = %List{records: [
      %Record{id: 1, fields: %{cool: "beans"}},
      %Record{id: 2, fields: %{neato: "mosquito"}},
    ]}
    assert Cache.set_all(cache, list)
    assert {:ok, %List{} = list} = Cache.get_all(cache)
  end
end
