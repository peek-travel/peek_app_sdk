defmodule PeekAppSDK.Demo do
  @moduledoc """
  Provides demo-related functionality for PeekAppSDK.
  """

  @doc """
  Returns the list of static paths that should be served by the endpoint.
  """
  def static_paths, do: ~w(assets fonts images favicon.ico robots.txt)
end
