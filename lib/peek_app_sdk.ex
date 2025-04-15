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
    peek_api_url: "https://apps.peekapis.com/backoffice-gql",
    peek_app_key: "APP_KEY",
    # Health API configuration
    health_api_url: "https://peek-labs-app-health-metrics.web.app",
    health_api_key: "HEALTH_API_KEY",
    # Centralized app configurations
    apps: [
      project_name: [peek_app_id: "project_name_APP_ID", peek_app_secret: "project_name_APP_SECRET"],
      another_app: [peek_app_id: "ANOTHER_APP_ID", peek_app_secret: "ANOTHER_APP_SECRET"]
    ]
  ```

  Note that `peek_api_url` and `peek_app_key` are always taken from the default
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
        peek_api_url: "https://apps.peekapis.com/backoffice-gql",
        peek_app_key: "default_app_key"
      }

  Using the default configuration:

      iex> PeekAppSDK.get_config()
      %{
        peek_app_secret: "default_secret",
        peek_app_id: "default_app_id",
        peek_api_url: "https://apps.peekapis.com/backoffice-gql",
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

      iex> PeekAppSDK.query_peek_pro("install_id", "query { test }", %{}, :project_name)
      {:ok, %{test: "success"}}
  """
  @spec query_peek_pro(String.t(), String.t(), map(), atom() | nil) ::
          {:ok, map()} | {:error, any()}
  defdelegate query_peek_pro(install_id, gql_query, gql_variables \\ %{}, config_id \\ nil),
    to: PeekAppSDK.Client

  @doc """
  Tracks an event for a monitored application using the Health API.

  ## Examples

  Using the default configuration:

      iex> payload = %PeekAppSDK.Health.Models.EventPayload{
      ...>   event_id: "app.install",
      ...>   level: :info,
      ...>   anonymous_id: "anon-123456"
      ...> }
      iex> PeekAppSDK.track_event("app-123", payload)
      {:ok, %{success: true, message: "Event tracked successfully", event_id: "1625097600000_abc123"}}

  Using a specific application's configuration:

      iex> payload = %PeekAppSDK.Health.Models.EventPayload{
      ...>   event_id: "app.install",
      ...>   level: :info,
      ...>   anonymous_id: "anon-123456"
      ...> }
      iex> PeekAppSDK.track_event("app-123", payload, :project_name)
      {:ok, %{success: true, message: "Event tracked successfully", event_id: "1625097600000_abc123"}}
  """
  @spec track_event(String.t(), PeekAppSDK.Health.Models.EventPayload.t(), atom() | nil) ::
          {:ok, map()} | {:error, any()}
  defdelegate track_event(monitored_app_id, payload, config_id \\ nil),
    to: PeekAppSDK.Health

  @doc """
  Tracks an info-level event for a monitored application using the Health API.

  ## Examples

  Using the default configuration:

      iex> PeekAppSDK.track_info_event("app-123", "app.install", "anon-123456")
      {:ok, %{success: true, message: "Event tracked successfully", event_id: "1625097600000_abc123"}}

  Using a specific application's configuration:

      iex> PeekAppSDK.track_info_event("app-123", "app.install", "anon-123456", %{}, :project_name)
      {:ok, %{success: true, message: "Event tracked successfully", event_id: "1625097600000_abc123"}}
  """
  @spec track_info_event(String.t(), String.t(), String.t(), map(), atom() | nil) ::
          {:ok, map()} | {:error, any()}
  defdelegate track_info_event(
                monitored_app_id,
                event_id,
                anonymous_id,
                opts \\ %{},
                config_id \\ nil
              ),
              to: PeekAppSDK.Health

  @doc """
  Tracks an error-level event for a monitored application using the Health API.

  ## Examples

  Using the default configuration:

      iex> PeekAppSDK.track_error_event("app-123", "app.error", "anon-123456")
      {:ok, %{success: true, message: "Event tracked successfully", event_id: "1625097600000_abc123"}}

  Using a specific application's configuration:

      iex> PeekAppSDK.track_error_event("app-123", "app.error", "anon-123456", %{}, :project_name)
      {:ok, %{success: true, message: "Event tracked successfully", event_id: "1625097600000_abc123"}}
  """
  @spec track_error_event(String.t(), String.t(), String.t(), map(), atom() | nil) ::
          {:ok, map()} | {:error, any()}
  defdelegate track_error_event(
                monitored_app_id,
                event_id,
                anonymous_id,
                opts \\ %{},
                config_id \\ nil
              ),
              to: PeekAppSDK.Health
end
