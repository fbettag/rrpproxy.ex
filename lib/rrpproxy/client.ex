defmodule RRPproxy.Client do
  @moduledoc """
  Documentation for `RRPproxy.Client` which holds API credentials.

  **It is used for low-level communication and should not be used directly by users of this library.**
  """
  @type t() :: %__MODULE__{username: String.t(), password: String.t(), ote: boolean()}
  defstruct username: "", password: "", ote: true

  @doc """
  Creates a new API Credentials object.
  """
  @spec new(String.t() | nil, String.t() | nil, boolean() | nil) :: t()
  def new(
        username \\ Application.get_env(:rrpproxy, :username),
        password \\ Application.get_env(:rrpproxy, :password),
        ote \\ Application.get_env(:rrpproxy, :ote, true)
      ) do
    %__MODULE__{ote: ote, username: username, password: password}
  end
end
