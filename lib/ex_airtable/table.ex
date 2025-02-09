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

  @optional_callbacks list_params: 0, schema: 0

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

  @doc """
  (Optional) A map of parameters that you wish to send to Airtable when either `list/1` or `list_async/1` is called.

  You would define this if you want your local `MyTable.list` and `ExAirtable.list(MyTable)` functions to always return a filtered query from Airtable.

  ## Examples

      # To filter records by a boolean "Approved" field, and only return the "Name" and "Picture", your params might look like this:
      def list_params do
        [
          filterByFormula: "{Approved}",
          fields: "Name",
          fields: "Picture"
        ]
      end

  See [here](https://codepen.io/airtable/full/rLKkYB) for more details about the available Airtable List API options.
  """
  @callback list_params() :: Keyword.t()

  @doc "The name of your table within Airtable"
  @callback name() :: String.t()

  @doc """
  (Optional) A map converting Airtable field names to local schema field names.

  This is handy for situations (passing attributes to ecto schemas, for
  example) where you may want different in-app field names than the fields you
  get from Airtable.

  If you don't define this method, the default is to simply use Airtable field
  names as the schema.

  ## Examples

      # If you want atom field names for your schema map...
      def schema do
        %{
          "Airtable Field Name" => :local_field_name,
          "Other Airtable Field" => :other_local_field
        }
      end

      iex> ExAirtable.Airtable.Record.to_schema(record, MyTable.schema)
      %{airtable_id: "rec1234", local_field_name: "value", other_local_field: "other value"}

      # If you want string field names for your schema map...
      def schema do
        %{
          "Airtable Field Name" => "local_field_name",
          "Other Airtable Field" => "other_local_field"
        }
      end

      iex> ExAirtable.Airtable.Record.to_schema(record, MyTable.schema)
      %{"airtable_id" => "rec1234", "local_field_name" => "value", "other_local_field" => "other value"}

  See also `to_schema/1` and `from_schema/1`.
  """
  @callback schema() :: map()

  @doc false
  def update_params(list_params, opts) do
    params =
      Keyword.get(opts, :params, [])
      |> Keyword.merge(list_params)

    Keyword.put(opts, :params, params)
  end

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
      Delete a single or list of records by ID from an Airtable.
      """
      def delete(id) when is_binary(id) do
        Service.delete(table(), id)
      end

      def delete(list) when is_list(list) do
        Service.delete(table(), list)
      end

      @doc """
      Convert an attribute map back to an %ExAirtable.Airtable.Record().

      Airtable field names are converted to local field names based on the
      `%{"Schema" => "map"}` defined (or overridden) in `schema/1`.

      See `ExAirtable.Airtable.Record.from_schema/2` for more details about the conversion.
      """
      def from_schema(attrs) when is_map(attrs) do
        Airtable.Record.from_schema(__MODULE__, attrs)
      end

      @doc """
      Get all records from your Airtable. See `Service.list/3` for details.
      """
      def list(opts \\ []) do
        Service.list(table(), ExAirtable.Table.update_params(list_params(), opts))
      end

      defoverridable list: 1

      @doc """
      Similar to `list/1`, except results aren't automatically concatenated
      with multiple API requests.

      Typically called automatically by a TableSynchronizer process.
      """
      def list_async(opts \\ []) do
        Service.list_async(table(), ExAirtable.Table.update_params(list_params(), opts))
      end

      defoverridable list_async: 1

      @doc false
      def list_params, do: []

      defoverridable list_params: 0

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
      Convert a record to an attribute map.

      Airtable field names are converted to local field names based on the
      `%{"Schema" => "map"}` defined (or overridden) in `schema/1`.

      See `ExAirtable.Airtable.Record.to_schema/2` for more details about the conversion.
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
