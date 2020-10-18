defmodule ExAirtable.Airtable.Record do
  @moduledoc """
  Struct for an Airtable Record. This should directly match the results returned from any Airtable REST API endpoint that returns records.
  """

  @derive {Jason.Encoder, except: [:createdTime]}

  defstruct id: nil,
            fields: %{},
            createdTime: nil

  @type t :: %__MODULE__{
    id: String.t(),
    fields: %{},
    createdTime: String.t()
  }

  @doc """
  Convert a typical Airtable JSON response into a %Record{}
  """
  def from_map(map) when is_map(map) do
    %__MODULE__{
      id: Map.get(map, "id"),
      fields: Map.get(map, "fields", []),
      createdTime: Map.get(map, "createdTime")
    }
  end
  def from_map(other), do: other
end
