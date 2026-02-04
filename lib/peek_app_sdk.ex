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
  PeekAppSDK.query_peek_pro("install_id", "query { test }", %{}, :project_name)
  ```

  ## Configuration

  Configure your application with the required PeekAppSDK settings:

  ```elixir
  # In config/config.exs or similar
  config :peek_app_sdk,
    peek_app_secret: "DEFAULT_SECRET",
    peek_app_id: "DEFAULT_APP_ID",
    peek_api_base_url: "https://apps.peekapis.com/",
    peek_api_key: "API_KEY",
    # Centralized app configurations
    apps: [
      project_name: [peek_app_id: "project_name_APP_ID", peek_app_secret: "project_name_APP_SECRET"],
      another_app: [peek_app_id: "ANOTHER_APP_ID", peek_app_secret: "ANOTHER_APP_SECRET"]
    ]
  ```

  Note that `peek_api_base_url` and `peek_api_key` are always taken from the default
  `:peek_app_sdk` configuration, regardless of which application identifier is used.
  """

  @doc """
  Gets the configuration for the given identifier.
  If no identifier is provided, returns the default configuration.

  ## Examples

  Using an application identifier:

      iex> PeekAppSDK.get_config(:project_name)
      %{
        peek_app_secret: "project_name_secret",
        peek_app_id: "project_name_app_id",
        peek_api_base_url: "https://apps.peekapis.com",
        peek_api_key: "default_api_key"
      }

  Using the default configuration:

      iex> PeekAppSDK.get_config()
      %{
        peek_app_secret: "default_secret",
        peek_app_id: "default_app_id",
        peek_api_base_url: "https://apps.peekapis.com",
        peek_api_key: "default_api_key"
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

      iex> PeekAppSDK.query_peek_pro("install_id", "query { test }", %{}, :project_name)
      {:ok, %{test: "success"}}
  """
  @spec query_peek_pro(String.t(), String.t(), map(), atom() | nil) ::
          {:ok, map()} | {:error, any()}
  defdelegate query_peek_pro(install_id, gql_query, gql_variables \\ %{}, config_id \\ nil),
    to: PeekAppSDK.Client

  defdelegate query_peek_pro_v2(install_id, gql_query, gql_variables \\ %{}),
    to: PeekAppSDK.Client
end
