defmodule ExAirtable.Config.Table do
  @moduledoc """
  Configuration struct for an Airtable "base"
  """

  alias ExAirtable.Config

  defstruct base: %Config.Base{}, name: nil

  @typedoc """
  A configuration for an Airtable Table - a reference to a `%Base{}` and a name.
  """
  @type t :: %__MODULE__{
    base: Config.Base.t(),
    name: String.t()
  }
end
