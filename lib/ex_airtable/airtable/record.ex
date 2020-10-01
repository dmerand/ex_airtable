defmodule ExAirtable.Airtable.Record do
  @moduledoc """
  Struct for an Airtable Record
  """

  @derive {Jason.Encoder, except: [:id, :createdTime]}

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
      id: map["id"],
      fields: map["fields"],
      createdTime: map["createdTime"]
    }
  end
  def from_map(other), do: other
end
