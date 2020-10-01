defmodule ExAirtable.Service do
  @moduledoc """
  This is where the bulk of the work happens to request and modify data in an Airtable table.

  These methods can be called directly, provided you have a valid `%ExAirtable.Config.Table{}` configuration. Alternatively, you can define a module that "inherits" this behavior - see `Table` for more details.

  ## Examples
    
      iex> table = %ExAirtable.Config.Table{
        base: %ExAirtable.Config.Base{
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

  alias ExAirtable.{Airtable, Config}

  @doc """
  Create a record in Airtable. Pass in a valid `%Airtable.List{}` struct.
  """
  def create(%Config.Table{} = table, %Airtable.List{} = list) do
    perform_request(table, method: :post, body: Jason.encode!(list))
    |> Airtable.List.from_map()
  end

  @doc """
  Get all records from a `%Config.Table{}`. Returns an `%Airtable.List{}` on success, and an `{:error, reason}` tuple on failure.

  Valid options are:

    - `params` - any parameters you wish to send along to the Airtable API (for example `view: "My View"` or `sort: "My Field"`. See `https://airtable.com/YOURBASEID/api/docs` for details (in the "List Records" sections).


  ## Examples
      iex> list(table, params: %{view: "My View Name"})
      %Airtable.List{}
  """
  def list(%Config.Table{} = table, opts \\ []) do
    perform_request(table, opts)
    |> Airtable.List.from_map()
    |> append_to_paginated_list(table, opts)
  end

  @doc """
  Get a single record from a `%Config.Table{}`, matching by ID. Returns an `%Airtable.Record{}` on success and an `{:error, reason}` tuple on failure.
  """
  def retrieve(%Config.Table{} = table, id) when is_binary(id) do
    perform_request(table, url_suffix: "/" <> id)
    |> Airtable.Record.from_map
  end

  defp append_to_paginated_list(%Airtable.List{offset: offset} = list, %Config.Table{} = table, opts) when is_binary(offset) do
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

  defp base_url(%Config.Table{} = table, suffix) when is_binary(suffix) do
    table.base.endpoint_url <> "/" <> 
      URI.encode(table.base.id) <> "/" <> 
      URI.encode(table.name) <> 
      URI.encode(suffix)
  end

  defp default_headers(%Config.Table{} = table) do
    %{
      "Authorization": "Bearer #{table.base.api_key}",
      "Content-Type": "application/json"
    }
  end

  defp perform_request(table, opts) when is_list(opts) do
    request_data = %HTTPoison.Request{
      body: Keyword.get(opts, :body, ""),
      headers: default_headers(table),
      method: Keyword.get(opts, :method, :get),
      params: Keyword.get(opts, :params),
      url: base_url(table, Keyword.get(opts, :url_suffix, ""))
    }

    case request(request_data) do
      {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
        body
        |> Jason.decode!
      {:ok, %HTTPoison.Response{status_code: 429}} ->
        Process.sleep(:timer.seconds(30))
        perform_request(table, opts)
      {:ok, %HTTPoison.Response{} = response} ->
        {:error, response}
      {:error, %HTTPoison.Error{reason: reason}} ->
        {:error, reason}
    end
  end
end
