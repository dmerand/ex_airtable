defmodule ExAirtable.Config.Base do
  @moduledoc """
  Configuration struct for an Airtable "base".

  This is extracted into a separate type/module so that it can be more easily centrlized in systems that implement multiple tables / bases.
  """

  defstruct id: nil,
            api_key: nil,
            endpoint_url: "https://api.airtable.com/v0"

  @typedoc """
  A configuration for an Airtable Base.
  """
  @type t :: %__MODULE__{
          id: String.t(),
          api_key: String.t(),
          endpoint_url: String.t()
        }
end
