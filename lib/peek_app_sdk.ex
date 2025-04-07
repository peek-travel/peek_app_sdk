defmodule PeekAppSDK do
  @moduledoc """
  PeekAppSDK provides functionality for authenticating requests to and from PeekPro when writing apps.

  This library supports multiple configurations, allowing different applications to use their own
  credentials and settings.

  ## Basic Usage

  ```elixir
  # Using the default configuration
  PeekAppSDK.query_peek_pro("install_id", "query { test }")

  # Using a specific application's configuration
  PeekAppSDK.query_peek_pro("install_id", "query { test }", %{}, :semnox)
  ```

  ## Configuration

  Configure your application with the required PeekAppSDK settings:

  ```elixir
  # In config/config.exs or similar
  config :semnox,
    peek_app_secret: "YOUR_APP_SECRET",
    peek_app_id: "YOUR_APP_ID"

  # The default configuration is set in :peek_app_sdk
  config :peek_app_sdk,
    peek_api_url: "https://api.peek.com",
    peek_app_secret: "DEFAULT_SECRET",
    peek_app_id: "DEFAULT_APP_ID",
    peek_app_key: "APP_KEY"
  ```

  Note that `peek_api_url` and `peek_app_key` are always taken from the default
  `:peek_app_sdk` configuration, regardless of which application identifier is used.
  """

  @doc """
  Gets the configuration for the given identifier.
  If no identifier is provided, returns the default configuration.

  ## Examples

  Using an application identifier:

      iex> PeekAppSDK.get_config(:semnox)
      %{
        peek_app_secret: "semnox_secret",
        peek_app_id: "semnox_app_id",
        peek_api_url: "https://api.peek.com",
        peek_app_key: "default_app_key"
      }

  Using the default configuration:

      iex> PeekAppSDK.get_config()
      %{
        peek_app_secret: "default_secret",
        peek_app_id: "default_app_id",
        peek_api_url: "https://api.peek.com",
        peek_app_key: "default_app_key"
      }
  """
  @spec get_config(atom() | nil) :: map()
  defdelegate get_config(identifier \\ nil), to: PeekAppSDK.Config

  @doc """
  Queries the Peek Pro API.

  ## Examples

  Using the default configuration:

      iex> PeekAppSDK.query_peek_pro("install_id", "query { test }")
      {:ok, %{test: "success"}}

  Using a specific application's configuration:

      iex> PeekAppSDK.query_peek_pro("install_id", "query { test }", %{}, :semnox)
      {:ok, %{test: "success"}}
  """
  @spec query_peek_pro(String.t(), String.t(), map(), atom() | nil) ::
          {:ok, map()} | {:error, any()}
  defdelegate query_peek_pro(install_id, gql_query, gql_variables \\ %{}, config_id \\ nil),
    to: PeekAppSDK.Client
end
