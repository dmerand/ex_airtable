defmodule ExAirtable.Service do
  @moduledoc """
  This is where the bulk of the work happens to request and modify data in an Airtable table.

  These methods can be called directly, provided you have a valid `%ExAirtable.Table{}` configuration. Alternatively, you can define a module that "inherits" this behavior - see `Table` for more details.

  ## Examples
    
      iex> table = %ExAirtable.Table{
        base: %ExAirtable.Base{
          id: "your base ID",
          api_key: "your api key"
        },
        name: "My Airtable Table Name"
      } 
      iex> list(table)
      %Airtable.List{}

      iex> retrieve(table, "rec1234")
      %Airtable.Record{}
  """

  use HTTPoison.Base

  alias ExAirtable.{Airtable, Table}

  @doc """
  Get all records from a `%Table{}`. Returns an `%Airtable.List{}` on success, and an `{:error, reason}` tuple on failure.

  Valid options are:

    - `params` - any parameters you wish to send along to the Airtable API (for example `view: "My View"` or `sort: "My Field"`. See `https://airtable.com/YOURBASEID/api/docs` for details (in the "List Records" sections).


  ## Examples
      iex> list(table, params: %{view: "My View Name"})
      %Airtable.List{}
  """
  def list(%Table{} = table, opts \\ []) do
    perform_get(table, opts)
    |> Airtable.List.from_map()
    |> append_to_paginated_list(table, opts)
  end

  @doc """
  Get a single record from a `%Table{}`, matching by ID. Returns an `%Airtable.Record{}` on success and an `{:error, reason}` tuple on failure.
  """
  def retrieve(%Table{} = table, id) when is_binary(id) do
    perform_get(table, url_suffix: "/" <> id)
    |> Airtable.Record.from_map
  end

  defp append_to_paginated_list(%Airtable.List{offset: offset} = list, %Table{} = table, opts) when is_binary(offset) do
    params = Keyword.get(opts, :params, %{}) |> Map.put(:offset, offset)
    opts = Keyword.put(opts, :params, params)
    new_list = list(table, opts)
    
    case new_list do
      %Airtable.List{} ->
        new_records = [list.records | new_list.records] |> List.flatten
        %{list | records: new_records}
      _anything_else ->
        new_list
    end
  end
  defp append_to_paginated_list(list, _table, _opts), do: list

  defp base_url(%Table{} = table, suffix) when is_binary(suffix) do
    table.base.endpoint_url <> "/" <> 
      URI.encode(table.base.id) <> "/" <> 
      URI.encode(table.name) <> 
      URI.encode(suffix)
  end

  defp default_headers(%Table{} = table) do
    %{"Authorization": "Bearer #{table.base.api_key}"}
  end

  defp perform_get(table, opts \\ []) do
    request_data = %HTTPoison.Request{
      url: base_url(table, Keyword.get(opts, :url_suffix, "")),
      headers: default_headers(table),
      params: Keyword.get(opts, :params)
    }

    case request(request_data) do
      {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
        body
        |> Poison.decode!
      {:ok, %HTTPoison.Response{status_code: 404}} ->
        {:error, :not_found}
      {:ok, %HTTPoison.Response{status_code: 429}} ->
        Process.sleep(:timer.seconds(30))
        perform_get(opts)
      {:error, %HTTPoison.Error{reason: reason}} ->
        {:error, reason}
    end
  end
end
