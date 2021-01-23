defmodule RRPproxy.Deserializer do
  @moduledoc """
  Documentation for `RRPproxy.Deserializer` which provides deserialization helpers.

  **It is used for low-level communication and should not be used directly by users of this library.**
  """
  @multi_line_fields [
    " procedure",
    " policy",
    "allowed characters notes",
    "restrictions",
    "tag"
  ]

  defp to_value(value) do
    String.to_integer(value)
  rescue
    ArgumentError ->
      try do
        String.to_float(value)
      rescue
        ArgumentError -> value
      end
  end

  defp to_bool("true"), do: true
  defp to_bool("false"), do: false
  defp to_bool(1), do: true
  defp to_bool(0), do: false
  defp to_bool(value), do: value

  defp is_multi_line_field(field), do: Enum.any?(@multi_line_fields, &String.contains?(field, &1))

  defp case_parts({data, info, extra}, ["column", "0"], value, _is_multi_line, _is_single_result) do
    {data, Map.put(info, :column, value), extra}
  end

  defp case_parts({data, info, extra}, ["first", "0"], value, _is_multi_line, _is_single_result) do
    {data, Map.put(info, :offset, String.to_integer(value)), extra}
  end

  defp case_parts({data, info, extra}, ["last", "0"], value, _is_multi_line, _is_single_result) do
    {data, Map.put(info, :last, String.to_integer(value)), extra}
  end

  defp case_parts({data, info, extra}, ["limit", "0"], value, _is_multi_line, _is_single_result) do
    {data, Map.put(info, :limit, String.to_integer(value)), extra}
  end

  defp case_parts({data, info, extra}, ["total", "0"], value, _is_multi_line, _is_single_result) do
    {data, Map.put(info, :total, String.to_integer(value)), extra}
  end

  defp case_parts({data, info, extra}, ["count", "0"], value, _is_multi_line, _is_single_result) do
    {data, Map.put(info, :count, String.to_integer(value)), extra}
  end

  defp case_parts({data, info, extra}, [field, index], value, is_multi_line, is_single_result) do
    f =
      field
      |> String.replace(" ", "_")
      |> String.downcase()
      |> String.to_atom()

    v =
      value
      |> to_value()
      |> to_bool()

    cond do
      is_multi_line and is_multi_line_field(field) ->
        new_value = Map.get(extra, f, "") <> "#{v}"
        {data, info, Map.put(extra, f, new_value)}

      is_single_result ->
        index_data = Map.get(data, "0", %{})

        index_data =
          if Map.has_key?(index_data, f) do
            new_value =
              case Map.get(index_data, f) do
                arr when is_list(arr) -> arr ++ [v]
                old_value -> [old_value, v]
              end

            Map.put(index_data, f, new_value)
          else
            Map.put(index_data, f, v)
          end

        {Map.put(data, "0", index_data), info, extra}

      true ->
        index_data = Map.get(data, "#{index}", %{})

        index_data =
          if Map.has_key?(index_data, f) do
            new_value = Map.get(index_data, f) <> "#{v}"
            Map.put(index_data, f, new_value)
          else
            Map.put(index_data, f, v)
          end

        {Map.put(data, "#{index}", index_data), info, extra}
    end
  end

  defp case_parts(main, _, _, _, _), do: main

  @doc "Transforms a Tesla results into a map structure."
  @spec to_map({:ok, Tesla.Env.t()} | {:error, any()}, boolean(), boolean()) ::
          {:ok, map()} | {:error, any()}
  def to_map(
        {:ok, %Tesla.Env{status: status, body: body}},
        is_multi_line_response,
        is_single_result
      ) do
    String.split(body, "\n")
    |> Enum.filter(&String.contains?(&1, "="))
    |> Enum.map(&Regex.split(~r/\s*=\s*/, &1, parts: 2))
    |> List.pop_at(0)
    |> work_parts(status, is_multi_line_response, is_single_result)
  end

  def to_map({:ok, %Tesla.Env{status: status}}, _, _),
    do: {:error, %{code: status}}

  def to_map({:error, _} = error, _, _), do: error

  defp work_parts({nil, []}, _, _, _), do: {:error, :bad_response}

  defp work_parts({[_, rcode], parts}, status, is_multi_line_response, is_single_result) do
    {[_, rdesc], parts} = List.pop_at(parts, 0)

    {data, info, extra} =
      Enum.reduce(parts, {%{}, %{}, %{}}, fn [k, v], red ->
        parts =
          Regex.split(~r/(\]\[|\]|\[)/, k)
          |> Enum.filter(fn x -> x != "" end)
          |> List.delete_at(0)

        case_parts(red, parts, v, is_multi_line_response, is_single_result)
      end)

    data = Enum.map(data, fn {_, v} -> v end)

    data =
      if Enum.count(data) > 1 do
        data
      else
        case Enum.at(data, 0) do
          nil -> []
          only_data -> [Map.merge(only_data, extra)]
        end
      end

    rcode = String.to_integer(rcode)

    code =
      if status >= 300 or rcode >= 300,
        do: :error,
        else: :ok

    {code, %{code: rcode, description: rdesc, data: data, info: info}}
  end
end
