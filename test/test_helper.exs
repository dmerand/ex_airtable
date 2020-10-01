ExUnit.start()

alias ExAirtable.{Airtable, Config}

defmodule ExAirtable.ExternalTable do
  use ExAirtable.Table

  def base, do: %Config.Base{
    id: System.get_env("BASE_ID"),
    api_key: System.get_env("API_KEY")
  }
  def name, do: System.get_env("TABLE_NAME")
end

defmodule ExAirtable.MockTable do
  use ExAirtable.Table

  def base, do: %Config.Base{id: "Mock ID", api_key: "Who Cares?"}
  def name, do: System.get_env("TABLE_NAME")
  def retrieve(_id), do: record()
  def list(_opts), do: %Airtable.List{records: [record()]}
  defp record, do: %Airtable.Record{ id: "1", createdTime: "Today" }
end
