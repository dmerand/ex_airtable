defmodule ExAirtable.Service do
  @moduledoc """
  This module is where we directly hit the Airtable API. Most methods take an `Airtable.Config.Table{}`, along with parameters to be forwarded to the REST API.

  These methods can be called directly, provided you have a valid `%ExAirtable.Config.Table{}` configuration. Alternatively, you can define a module that "inherits" this behavior - see `ExAirtable.Table` for more details.

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
  
  Returns an `%Airtable.List{}` on success.

  ## Example

      iex> create(table, %List{})
      %List{}

      iex> create(table, list_with_errors)
      {:error, reason}
  """
  def create(%Config.Table{} = table, %Airtable.List{} = list) do
    body =
      list
      |> remove_objectionable_fields()
      |> Jason.encode!()

    perform_request(table, method: :post, body: body)
    |> Airtable.List.from_map()
  end

  @doc """
  Delete a single record (by ID) from an Airtable

  ## Example
      
      iex> delete(table, "recJmmAR0IzpaekBn")
      %{"deleted" => true, "id" => "recJmmAR0IzpaekBn"}
  """
  def delete(%Config.Table{} = table, id) when is_binary(id) do
    perform_request(table, method: :delete, url_suffix: "/#{id}")
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

  @doc """
  Update a `List{}` of `Record{}`s in Airtable.

  Valid options include:

  - `objectionable_fields` - A list of field names to remove from the `fields` entry of any `Record` in your `List`. This is typically used if you're trying to update in a table that doesn't allow updating certain (calculated) fields.
  - `overwrite` - Will overwrite all values in the destination record with values being sent. Default is false, which will only update fields that have values (ie aren't null).
  """
  def update(%Config.Table{} = table, %Airtable.List{} = list, opts \\ []) do
    method = case Keyword.fetch(opts, :overwrite) do
      true -> :put
      _ -> :patch
    end

    body =
      list
      |> remove_objectionable_fields(Keyword.get(opts, :objectionable_fields, []))
      |> Jason.encode!()

    perform_request(table, method: method, body: body)
    |> Airtable.List.from_map()
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

  defp remove_objectionable_fields(%Airtable.List{} = list, fields \\ [:id]) do
    # Airtable really doesn't like createdTime being in any pushes.
    fields = [:createdTime] ++ fields

    %{list | records: Enum.map(list.records, fn record ->
      Enum.reduce(fields, Map.from_struct(record), fn field, acc ->
        %{Map.delete(acc, field) | fields:
          Map.delete(acc.fields, field)
        }
      end)
    end)}
  end
end
