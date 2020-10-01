defmodule ExAirtable.Table do
  @moduledoc """
  The `Table` interface allows you to define your own modules that use Airtables. It is a thin wrapper around `Service`, but often more convenient to use.

  ## Examples
  
      defmodule MyTable do
        use ExAirtable.Table

        def base, do: %ExAirtable.Base{
          id: "your base ID",
          api_key: "your api key"
        }
        def name, do: "My Airtable Table Name"
      end

      iex> MyTable.list()
      %ExAirtable.Airtable.List{} 

      iex> MyTable.retrieve("rec123")
      %ExAirtable.Airtable.Record{} 
  """

  alias ExAirtable.{Base, Service}

  defstruct base: %Base{}, name: nil

  @typedoc """
  A configuration for an Airtable Table - a reference to a `%Base{}` and a name.
  """
  @type t :: %__MODULE__{
    base: Base.t(),
    name: String.t()
  }

  @doc "A valid %ExAirtable.Base{} config for your table"
  @callback base :: Base.t()

  @doc "The name of your table within Airtable"
  @callback name() :: String.t()

  defmacro __using__(_) do
    quote do
      @behaviour ExAirtable.Table

      @doc """
      Get all records from your Airtable. See `Service.list/3` for details.
      """
      def list(opts \\ []) do
        Service.list table(), opts
      end

      @doc """
      Get a single record from your Airtable, matching by ID. See `Service.retrieve/2` for details.
      """
      def retrieve(id) when is_binary(id) do
        Service.retrieve table(), id
      end

      @doc """
      Utility function to return the table struct
      """
      def table() do
        %ExAirtable.Table{base: base(), name: name()}
      end
    end
  end
end
