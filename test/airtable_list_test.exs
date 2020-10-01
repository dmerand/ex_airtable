defmodule ExAirtable.Airtable.ListTest do
  use ExUnit.Case, async: true
  alias ExAirtable.Airtable.{List, Record}

  test "JSON Encode" do
    list = %List{records: [
      %Record{id: "recordID", fields: %{name: "value"}}
    ]}
    assert "{\"records\":[{\"fields\":{\"name\":\"value\"}}]}" = Jason.encode!(list)
  end
end
