defmodule ExAirtable.Airtable.List do
  @moduledoc """
  Struct for an Airtable List of Records. This should directly match results being sent/returned from the Airtable REST API.
  """

  @derive {Jason.Encoder, except: [:offset]}

  alias ExAirtable.Airtable.Record

  defstruct records: [], offset: nil

  @type t :: %__MODULE__{
    records: [Record.t()],
    offset: String.t()
  }


  @doc """
  Convert a typical Airtable JSON response into a %List{}
  """
  def from_map(map) when is_map(map) do
    %__MODULE__{
      records: Enum.map(map["records"], &Record.from_map/1),
      offset: Map.get(map, "offset")
    }
  end
  def from_map(other), do: other
end
