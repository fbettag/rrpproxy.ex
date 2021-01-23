defmodule RRPproxy.Connection do
  @moduledoc """
  Documentation for `RRPproxy.Connection` which provides low-level API functionality to the rrpproxy.net API.

  **It is used for low-level communication and should not be used directly by users of this library.**
  """
  require Logger
  import RRPproxy.Deserializer

  @doc """
  Creates a new API Connection with credentials.
  """
  @spec new(struct() | nil) :: Tesla.Env.client()
  def new(client \\ RRPproxy.Client.new()) do
    url =
      if client.ote == true,
        do: "https://api-ote.rrpproxy.net/api/call",
        else: "https://api.rrpproxy.net/api/call"

    [
      {Tesla.Middleware.BaseUrl, url},
      {Tesla.Middleware.Timeout, timeout: 30_000},
      {Tesla.Middleware.EncodeJson, engine: Poison, engine_opts: [keys: :atoms]},
      {Tesla.Middleware.Headers, [{"User-Agent", "Elixir"}]}
    ]
    |> Tesla.client()
  end

  @doc """
  Makes calls against the API with the given request.
  """
  @spec call(String.t(), keyword(), Tesla.Env.client() | nil, boolean() | nil, boolean() | nil) ::
          RRPproxy.return()
  def call(
        command,
        params \\ [],
        client \\ RRPproxy.Client.new(),
        is_multi_line_response \\ false,
        is_single_result \\ false
      ) do
    params = params ++ [s_login: client.username, s_pw: client.password, command: command]

    client
    |> new()
    |> request(params)
    |> response(client, params, is_multi_line_response, is_single_result, 1)
  end

  defp request(client, params) do
    client
    |> Tesla.get("", query: params)
  end

  defp retry(error, client, params, mlr, sr, tries) do
    if tries >= 3 do
      error
    else
      command = Keyword.get(params, :command)
      Logger.info("[RRPproxy] Retry #{tries}: #{command} #{inspect(params)}")
      :timer.sleep(:timer.seconds(tries * 5))

      client
      |> new()
      |> request(params)
      |> response(client, params, mlr, sr, tries + 1)
    end
  end

  defp response({:error, :bad_response} = error, client, params, mlr, sr, tries),
    do: retry(error, client, params, mlr, sr, tries)

  defp response({:error, :closed} = error, client, params, mlr, sr, tries),
    do: retry(error, client, params, mlr, sr, tries)

  defp response({:error, :timeout} = error, client, params, mlr, sr, tries),
    do: retry(error, client, params, mlr, sr, tries)

  defp response({:error, %{code: 421}} = error, client, params, mlr, sr, tries),
    do: retry(error, client, params, mlr, sr, tries)

  defp response({:error, %{code: 423}} = error, client, params, mlr, sr, tries),
    do: retry(error, client, params, mlr, sr, tries)

  defp response({:error, %{code: 500}} = error, client, params, mlr, sr, tries),
    do: retry(error, client, params, mlr, sr, tries)

  defp response(other, _, _, mlr, sr, _), do: to_map(other, mlr, sr)
end
