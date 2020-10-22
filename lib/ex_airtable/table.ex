defmodule ExAirtable.Table do
  @moduledoc """
  The `Table` behaviour allows you to define your own modules that use Airtables. 

  It is a thin wrapper around `Service`, but often more convenient to use.

  ## Examples

      defmodule MyTable do
        use ExAirtable.Table

        def base, do: %ExAirtable.Config.Base{
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

  alias ExAirtable.{Airtable, Config, Service}

  @optional_callbacks schema: 0

  @doc """
  A valid %ExAirtable.Config.Base{} config for your table.

  Often this will end up being in the application configuration somewhere, for example:

      # ... in your mix.config
      config :my_app, Airtable.Base, %{
        id: "base id",
        api_key: "api key"
      }

      # ... in your table module
      def base do
        struct(ExAirtable.Config.Base, Application.get_env(:my_all, Airtable.Base))
      end
  """
  @callback base() :: Config.Base.t()

  @doc "The name of your table within Airtable"
  @callback name() :: String.t()

  @doc """
  (Optional) A map converting Airtable field names to local schema field names.

  This is handy for situations (ecto schemas, for example) where you want different in-app field names than the fields you get from Airtable.

  If you don't define this method, the default is to simply use Airtable field names as the schema.

  ## Examples

      # If you want atom field names for your schema map...
      def schema do
        %{
          "Airtable Field Name" => :local_field_name,
          "Other Airtable Field" => :other_local_field
        }
      end

      iex> ExAirtable.Airtable.Record.to_schema(record, MyTable.schema)
      %{local_field_name: "value", other_local_field: "other value"}

      # If you want string field names for your schema map...
      def schema do
        %{
          "Airtable Field Name" => "local_field_name",
          "Other Airtable Field" => "other_local_field"
        }
      end

      iex> ExAirtable.Airtable.Record.to_schema(record, MyTable.schema)
      %{"local_field_name" => "value", "other_local_field" => "other value"}
  """
  @callback schema() :: map()

  defmacro __using__(_) do
    quote do
      @behaviour ExAirtable.Table

      @doc """
      Create a record in your Airtable. See `Service.create/2` for details.
      """
      def create(%Airtable.List{} = list) do
        Service.create(table(), list)
      end

      @doc """
      Delete a single record (by ID) from an Airtable
      """
      def delete(id) when is_binary(id) do
        Service.delete(table(), id)
      end

      @doc """
      Get all records from your Airtable. See `Service.list/3` for details.

      You may wish to override this function in your table module if you want your manual table listings to pass custom parameters (as a `params: %{}` in `opts`) to the Airtable API. See `ExAirtable.Service.list/2` for details.
      """
      def list(opts \\ []) do
        Service.list(table(), opts)
      end

      defoverridable list: 1

      @doc """
      Similar to `list/1`, except results aren't automatically concatenated with multiple API requests. 

      Typically called automatically by a TableSynchronizer

      You may wish to override this function in your table module if you want your cached table listings to pass custom parameters (as a `params: %{}` in `opts`) to the Airtable API. See `ExAirtable.Service.list/2` for details.
      """
      def list_async(opts \\ []) do
        Service.list_async(table(), opts)
      end

      defoverridable list_async: 1

      @doc """
      Get a single record from your Airtable, matching by ID. 

      See `Service.retrieve/2` for details.
      """
      def retrieve(id) when is_binary(id) do
        Service.retrieve(table(), id)
      end

      # Make overrideable for testing mocks
      defoverridable retrieve: 1

      @doc false
      def schema, do: nil

      defoverridable schema: 0

      @doc """
      Utility function to return the table struct
      """
      def table() do
        %Config.Table{base: base(), name: name()}
      end

      @doc """
      Convert a record to an internal schema, mapping Airtable field names to local field names based on a `%{"Schema" => "map"}`.

      See `ExAirtable.Airtable.Record.to_schema/2` for more details.
      """
      def to_schema(%Airtable.Record{} = record) do
        Airtable.Record.to_schema(record, schema())
      end

      @doc """
      Update a record in your Airtable. See `Service.update` for details.
      """
      def update(%Airtable.List{} = list, opts \\ []) do
        Service.update(table(), list, opts)
      end
    end
  end
end
