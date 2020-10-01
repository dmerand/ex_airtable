defmodule ExAirtable.Base do
  @moduledoc """
  Configuration struct for an Airtable "base"
  """

  defstruct id: nil, 
            api_key: nil,
            endpoint_url: "https://api.airtable.com/v0"

  @type t :: %__MODULE__{
    id: String.t(),
    api_key: String.t(),
    endpoint_url: String.t()
  }
end
