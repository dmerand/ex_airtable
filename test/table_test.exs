defmodule ExAirtable.TableTest do
  use ExUnit.Case, async: true
  alias ExAirtable.{Airtable, Base}

  defmodule ExternalTable do
    use ExAirtable.Table

    def base, do: %Base{
      id: System.get_env("BASE_ID"),
      api_key: System.get_env("API_KEY")
    }
    def name, do: System.get_env("TABLE_NAME")
  end

  defmodule MockTable do
    use ExAirtable.Table

    def base, do: %Base{id: "Mock ID", api_key: "Who Cares?"}
    def name, do: System.get_env("TABLE_NAME")
    def retrieve(_id), do: record()
    def list(_opts), do: %Airtable.List{records: [record()]}

    defp record do
      %Airtable.Record{
        id: "1",
        createdTime: "Today" 
      }
    end
  end

  test "use" do
    assert %Base{} = MockTable.base()
    assert MockTable.name() == "Videos"
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
    assert [%Airtable.Record{} | rest] = list.records
  end

  @tag :external_api
  test "get by erroneous ID" do
    assert {:error, _reason} = ExternalTable.retrieve("wat")
  end

  @tag :external_api
  test "list with a view" do
    list = ExternalTable.list(params: %{view: "Main View"})
    assert %Airtable.List{} = list
    assert [%Airtable.Record{} | rest] = list.records
  end

  @tag :external_api
  test "list with pagination" do
    full_list = ExternalTable.list()
    paginated_list = ExternalTable.list(params: %{limit: 10})
    assert Enum.count(full_list.records) == Enum.count(paginated_list.records)
  end
end
