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
  Convert a typical Airtable JSON response into a %List{}. Any weird response will return an empty list.
  """
  def from_map(%{"records" => records} = map) do
    %__MODULE__{
      records: Enum.map(records, &Record.from_map/1),
      offset: Map.get(map, "offset")
    }
  end
  def from_map(_other), do: %__MODULE__{}

  @doc """
  Filter the records in a list by a given function. See `Enum.filter` for examples.

  Returns an array of `%Record{}` structs.
  """
  def filter_records(%__MODULE__{} = list, fun) do
    Enum.filter list.records, fun
  end

  @doc """
  Given a list, a field name that corresponds to an Airtable "relationship" field, and a record ID (presumably from the related table), find all records in the list that are related on that field.

  ## Examples
  
      iex> filter_relations(list, "Users", "rec1234")
      [%Record{fields: %{"Users" => ["rec1234", "rec456"]}}, ...]

      iex> filter_relations(list, "Users", "invalid_id")
      []
  """
  def filter_relations(%__MODULE__{} = list, field, id) do
    Enum.filter(list.records, fn record ->
      Record.get(record, field, [])
      |> Enum.any?(& &1 == id)
    end)

  end
end
