defmodule PeekAppSDK.Config do
  @moduledoc """
  Provides configuration for PeekAppSDK.

  This module allows different applications to use their own configurations
  through a centralized configuration structure.

  ## Configuration

  Configure multiple applications in a single place:

  ```elixir
  config :peek_app_sdk,
    peek_app_secret: "DEFAULT_SECRET",
    peek_app_id: "DEFAULT_APP_ID",
    peek_api_base_url: "https://apps.peekapis.com",
    peek_api_key: "API_KEY",
    client_secret_token: "CLIENT_SECRET_TOKEN",
    apps: [
      project_name: [peek_app_id: "project_name_app_id", peek_app_secret: "project_name_secret", client_secret_token: "base64_key"],
      another_app: [peek_app_id: "another_app_id", peek_app_secret: "another_app_secret"]
    ]
  ```

  Note that `peek_api_base_url` and `peek_api_key` are always taken from the default
  `:peek_app_sdk` configuration, regardless of which application identifier is used.
  """

  @default_peek_api_base_url "https://apps.peekapis.com"

  @spec get_config() :: %{
          client_secret_token: any(),
          peek_api_base_url: any(),
          peek_app_id: any(),
          peek_api_key: any(),
          peek_app_secret: any()
        }
  @doc """
  Gets the configuration for the given identifier.
  If no identifier is provided, returns the default configuration from :peek_app_sdk.

  ## Examples

  Using an app identifier:

      iex> PeekAppSDK.Config.get_config(:project_name)
      %{
        peek_app_secret: "project_name_secret",
        peek_app_id: "project_name_app_id",
        peek_api_base_url: "https://apps.peekapis.com",
        peek_api_key: "default_api_key"
      }

  Using the default configuration:

      iex> PeekAppSDK.Config.get_config()
      %{
        peek_app_secret: "default_secret",
        peek_app_id: "default_app_id",
        peek_api_base_url: "https://apps.peekapis.com",
        peek_api_key: "default_api_key"
      }

  Note that `peek_api_base_url` and `peek_api_key` are always taken from the default
  `:peek_app_sdk` configuration, regardless of which application identifier is used.
  """
  @spec get_config(atom() | nil) :: map()
  def get_config(identifier \\ nil)

  def get_config(nil) do
    # Return the default configuration from :peek_app_sdk
    %{
      peek_app_secret: Application.get_env(:peek_app_sdk, :peek_app_secret),
      peek_app_id: Application.get_env(:peek_app_sdk, :peek_app_id),
      peek_api_base_url: Application.get_env(:peek_app_sdk, :peek_api_base_url, @default_peek_api_base_url) || @default_peek_api_base_url,
      peek_api_key: Application.get_env(:peek_app_sdk, :peek_api_key),
      client_secret_token: Application.get_env(:peek_app_sdk, :client_secret_token),
      posthog_key: Application.get_env(:peek_app_sdk, :posthog_key)
    }
  end

  def get_config(identifier) when is_atom(identifier) do
    # Get configuration from the centralized apps config
    apps = Application.get_env(:peek_app_sdk, :apps, [])
    app_config = Keyword.get(apps, identifier)

    if app_config && Keyword.has_key?(app_config, :peek_app_id) &&
         Keyword.has_key?(app_config, :peek_app_secret) do
      %{
        peek_app_secret: Keyword.get(app_config, :peek_app_secret),
        peek_app_id: Keyword.get(app_config, :peek_app_id),
        peek_api_base_url: Application.get_env(:peek_app_sdk, :peek_api_base_url, @default_peek_api_base_url),
        peek_api_key: Keyword.get(app_config, :peek_api_key),
        client_secret_token: Keyword.get(app_config, :client_secret_token)
      }
    else
      # Fall back to default configuration if the app is not configured
      get_config(nil)
    end
  end

  # Migration helper functions
  @doc """
  Checks for deprecated peek_api_url configuration and raises an error if found.
  This is called when using the update_configuration_status feature.
  """
  def check_deprecated_config! do
    if Application.get_env(:peek_app_sdk, :peek_api_url) do
      raise """
      Configuration error: peek_api_url is deprecated and no longer supported.

      Please update your configuration to use peek_api_base_url instead:

      OLD (deprecated):
        config :peek_app_sdk,
          peek_api_url: "https://apps.peekapis.com/backoffice-gql"

      NEW (required):
        config :peek_app_sdk,
          peek_api_base_url: "https://apps.peekapis.com"

      The SDK will automatically append the appropriate path (/backoffice-gql) when making API calls.
      """
    end
  end
end
