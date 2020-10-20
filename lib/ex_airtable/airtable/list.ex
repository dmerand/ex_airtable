defmodule ExAirtable.Airtable.List do
  @moduledoc """
  Struct for an Airtable List of Records. 

  This should directly match results being sent/returned from the Airtable REST API.
  """

  @derive {Jason.Encoder, except: [:offset]}

  alias ExAirtable.Airtable.Record

  defstruct records: [], offset: nil

  @type t :: %__MODULE__{
          records: [Record.t()],
          offset: String.t()
        }

  @doc """
  Convert a typical Airtable JSON response into an %ExAirtable.Airtable.List{}. 

  Any weird response will return an empty list.
  """
  def from_map(%{"records" => records} = map) do
    %__MODULE__{
      records: Enum.map(records, &Record.from_map/1),
      offset: Map.get(map, "offset")
    }
  end

  def from_map(_other), do: %__MODULE__{}

  @doc """
  Filter the records in a list by a given function. 

  Returns an array of `%ExAirtable.Airtable.Record{}` structs.

  See `Enum.filter` for more examples.
  """
  def filter_records(%__MODULE__{} = list, fun) do
    Enum.filter(list.records, fun)
  end

  @doc """
  Find all records in a list that are related on a given field matching a given ID

  ## Examples

      iex> filter_relations(list, "Users", "rec1234")
      [%Record{fields: %{"Users" => ["rec1234", "rec456"]}}, ...]

      iex> filter_relations(list, "Users", "invalid_id")
      []
  """
  def filter_relations(%__MODULE__{} = list, field, id) do
    Enum.filter(list.records, fn record ->
      Record.get(record, field, [])
      |> Enum.any?(&(&1 == id))
    end)
  end
end
