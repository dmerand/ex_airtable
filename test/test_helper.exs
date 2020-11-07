ExUnit.start()

defmodule ExAirtable.MockTable do
  use ExAirtable.Table

  alias ExAirtable.{Airtable, Config}

  def base, do: %Config.Base{id: "Mock ID", api_key: "Who Cares?"}
  def name, do: "Mock Name"
  def retrieve(_id), do: record()
  def list(_opts), do: %Airtable.List{records: [record()]}
  def schema, do: %{"FieldOne" => :field_one, "FieldTwo" => :field_two}

  defp record,
    do: %Airtable.Record{
      id: "1",
      createdTime: "Today",
      fields: %{"FieldOne" => "One", "FieldTwo" => "Two"}
    }
end

defmodule ExAirtable.FauxTable do
  use ExAirtable.Table

  alias ExAirtable.{Airtable, Config}

  def base, do: %Config.Base{id: "Faux ID", api_key: "Who Cares?"}
  def name, do: "Faux / Name"
  def retrieve(_id), do: record()
  def list(_opts), do: %Airtable.List{records: [record()]}

  defp record,
    do: %Airtable.Record{
      id: "1",
      createdTime: "Today",
      fields: %{"FieldOne" => "One", "FieldTwo" => "Two"}
    }
end
