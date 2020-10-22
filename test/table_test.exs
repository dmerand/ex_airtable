defmodule ExAirtable.TableTest do
  use ExUnit.Case, async: true
  alias ExAirtable.{Airtable, Config, FauxTable, MockTable}
  alias ExAirtable.Example.EnvTable

  test "use" do
    assert %Config.Base{} = MockTable.base()
    assert MockTable.name() == "Mock Name"
  end

  test "get by ID" do
    record = MockTable.retrieve("recg9FKpihuQyYXET")
    assert %Airtable.Record{} = record
    assert record.id
    assert %{} = record.fields
    assert record.createdTime
  end

  test "list all" do
    list = MockTable.list()
    assert %Airtable.List{} = list
    assert [%Airtable.Record{} | _rest] = list.records
  end

  @tag :external_api
  test "get by erroneous ID" do
    assert {:error, _reason} = EnvTable.retrieve("wat")
  end

  @tag :external_api
  test "list with a view" do
    list = EnvTable.list(params: [view: "Main View"])
    assert %Airtable.List{} = list
    assert [%Airtable.Record{} | _rest] = list.records
  end

  @tag :external_api
  test "list with pagination" do
    full_list = EnvTable.list()
    paginated_list = EnvTable.list(params: [limit: 10])
    assert Enum.count(full_list.records) == Enum.count(paginated_list.records)
  end

  @tag :external_mutation
  test "create" do
    list = %Airtable.List{
      records: [
        %Airtable.Record{
          fields: %{
            "Name" => "Test Name",
            "Description" => "Test Description"
          }
        }
      ]
    }

    assert %Airtable.List{} = EnvTable.create(list)
  end

  test "schema conversion with no given schema" do
    record = FauxTable.retrieve(1)
    assert %{"airtable_id" => "1", "FieldOne" => "One", "FieldTwo" => "Two"} = FauxTable.to_schema(record)
  end

  test "schema conversion with given schema" do
    record = MockTable.retrieve(1)
    assert %{airtable_id: "1", field_one: "One"} = MockTable.to_schema(record)
  end
end
