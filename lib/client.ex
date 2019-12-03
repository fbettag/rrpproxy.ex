defmodule RRPproxy.Client do
  @moduledoc """
  This client takes care of communication with the RRPproxy.net API.
  """

  use HTTPoison.Base
  require Logger

  defstruct username: Application.get_env(:rrpproxy, :username),
            password: Application.get_env(:rrpproxy, :password),
            ote: Application.get_env(:rrpproxy, :ote, true)

  defp make_url(ote) do
    if ote do
      "https://api-ote.rrpproxy.net/api/call"
    else
      "https://api.rrpproxy.net/api/call"
    end
  end

  defp fix_field_and_value(field, value) do
    f = String.replace(field, " ", "_")
        |> String.downcase()

    v = try do String.to_integer(value) rescue
      ArgumentError -> try do String.to_float(value) rescue ArgumentError -> value end
    end
    v = if v == 1 do true else if v == 0 do false else v end end

    {String.to_atom(f), v}
  end

  defp work_data_fields({data, info, extra}, field, index, value, is_multi_line) do
    {f, v} = fix_field_and_value(field, value)
    multi_line_fields = [" procedure", " policy", "allowed characters notes", "restrictions", "tag"]
    if is_multi_line and Enum.any?(multi_line_fields, fn p -> String.contains?(field, p) end) do
      new_value = Map.get(extra, f, "") <> "#{v}"
      {data, info, Map.put(extra, f, new_value)}
    else
      index_data = Map.get(data, "#{index}", %{})
      index_data = if Map.has_key?(index_data, f) do
        new_value = Map.get(index_data, f) <> "#{v}"
        Map.put(index_data, f, new_value)
      else
        Map.put(index_data, f, v)
      end
      {Map.put(data, "#{index}", index_data), info, extra}
    end
  end

  defp case_parts({data, info, extra} = main, parts, value, is_multi_line) do
    case parts do
      ["column", "0"] -> {data, Map.put(info, :column, value), extra}
      ["first", "0"] -> {data, Map.put(info, :offset, String.to_integer(value)), extra}
      ["last", "0"] -> {data, Map.put(info, :last, String.to_integer(value)), extra}
      ["limit", "0"] -> {data, Map.put(info, :limit, String.to_integer(value)), extra}
      ["total", "0"] -> {data, Map.put(info, :total, String.to_integer(value)), extra}
      ["count", "0"] -> {data, Map.put(info, :count, String.to_integer(value)), extra}
      [field, index] -> work_data_fields(main, field, index, value, is_multi_line)
      _ -> main
    end
  end

  defp response_to_map({:error, %HTTPoison.Error{id: _, reason: reason}}) do
    {:error, reason}
  end

  defp response_to_map({code, %{body: body}} = {_, %HTTPoison.Response{}}, is_multi_line_response \\ false) do
    parts = String.split(body, "\n")
           |> Enum.filter(&String.contains?(&1, "="))
           |> Enum.map(&Regex.split(~r/\s*=\s*/, &1, parts: 2))

    {[_, rcode], parts} = List.pop_at(parts, 0)
    {[_, rdesc], parts} = List.pop_at(parts, 0)

    {data, info, extra} = Enum.reduce(parts, {%{}, %{}, %{}}, fn [k, v], red ->
      parts = Regex.split(~r/(\]\[|\]|\[)/, k)
          |> Enum.filter(fn x -> x != "" end)
          |> List.delete_at(0)
      case_parts(red, parts, v, is_multi_line_response)
    end)

    data = Enum.map(data, fn {_, v} -> v end)
    data = if Enum.count(data) > 1 do data else
      with_extra = case Enum.at(data, 0) do
        nil -> []
        only_data -> [Map.merge(only_data, extra)]
      end
      with_extra
    end

    rcode = String.to_integer(rcode)
    code = if code == :ok and rcode >= 300 do :error else :ok end
    {code, %{code: rcode, description: rdesc, data: data, info: info}}
  end

  def query(command, custom_params \\ [], creds = %__MODULE__{} \\ %__MODULE__{}, is_multi_line_response \\ false) do
    query_tries(creds, command, custom_params, is_multi_line_response)
  end

  defp query_tries(creds, command, custom_params, is_multi_line_response, tries \\ 1) do
    url = make_url(creds.ote)
    request_params = [s_login: creds.username, s_pw: creds.password, command: command] ++ custom_params

    retry_func = fn error ->
      if tries > 3 do
        error # return the error as is
      else
        Logger.debug "[RRPproxy] retrying #{command} #{Kernel.inspect(custom_params)}, try: #{tries}"
        :timer.sleep(:timer.seconds(tries * 5))
        query_tries(creds, command, custom_params, is_multi_line_response, tries + 1)
      end
    end

    case response_to_map get(url, [], params: request_params) do
      {:error, :timeout} = error -> retry_func.(error)
      {:error, %{code: 421}} = error -> retry_func.(error)
      {:error, %{code: 423}} = error -> retry_func.(error)
      other -> other
    end
  end
end
