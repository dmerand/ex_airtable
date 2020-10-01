defmodule ExAirtable.TableTest do
  use ExUnit.Case, async: true
  alias ExAirtable.{Airtable, Base}

  defmodule SampleTable do
    use ExAirtable.Table

    def base, do: %ExAirtable.Base{
      id: System.get_env("BASE_ID"),
      api_key: System.get_env("API_KEY")
    }
    def name, do: System.get_env("TABLE_NAME")
  end

  test "use" do
    assert %Base{} = SampleTable.base()
    assert SampleTable.name() == "Videos"
  end

  @tag :external_api
  test "get by ID" do
    assert {:error, :not_found} = SampleTable.retrieve("wat")
    record = SampleTable.retrieve("recg9FKpihuQyYXET")
    assert %Airtable.Record{} = record
    assert record.id
    assert record.fields
    assert record.createdTime
  end

  @tag :external_api
  test "list all" do
    list = SampleTable.list()
    assert %Airtable.List{} = list
    assert [%Airtable.Record{} | rest] = list.records
  end

  @tag :external_api
  test "list with a view" do
    list = SampleTable.list(params: %{view: "Amazing View"})
    assert %Airtable.List{} = list
    assert [%Airtable.Record{} | rest] = list.records
  end

  @tag :external_api
  test "list with pagination" do
    full_list = SampleTable.list()
    paginated_list = SampleTable.list(params: %{limit: 10})
    assert Enum.count(full_list.records) == Enum.count(paginated_list.records)
  end
end
