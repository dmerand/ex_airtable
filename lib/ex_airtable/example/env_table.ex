defmodule ExAirtable.Example.EnvTable do
  @moduledoc """
  This is useful for playing around in the console.

  It'll load up a table based on whatever you have in your config. Try `make console` to quickly load the defaults.
  """
  use ExAirtable.Table
  alias ExAirtable.Config

  @impl ExAirtable.Table
  def base,
    do: %Config.Base{
      id: System.get_env("BASE_ID"),
      api_key: System.get_env("API_KEY")
    }

  @impl ExAirtable.Table
  def name, do: System.get_env("TABLE_NAME")
end
