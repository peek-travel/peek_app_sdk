defmodule PeekAppSDK.Config do
  @moduledoc """
  Provides configuration for PeekAppSDK.

  This module allows different applications to use their own configurations
  by reading from their respective application environment.

  For example, if you have a `:semnox` application, you can configure it with:

  ```elixir
  config :semnox,
    peek_app_secret: "semnox_secret",
    peek_app_id: "semnox_app_id"
  ```

  And then use `:semnox` as the config_id when calling PeekAppSDK functions.

  Note that `peek_api_url` and `peek_app_key` are always taken from the default
  `:peek_app_sdk` configuration, regardless of which application identifier is used.
  """

  @default_peek_url "https://apps.peekapis.com/backoffice-gql"

  @doc """
  Gets the configuration for the given identifier.
  If no identifier is provided, returns the default configuration from :peek_app_sdk.

  ## Examples

  Using an atom identifier:

      iex> PeekAppSDK.Config.get_config(:semnox)
      %{
        peek_app_secret: "semnox_secret",
        peek_app_id: "semnox_app_id",
        peek_api_url: "https://api.peek.com",
        peek_app_key: "default_app_key"
      }

  Using the default configuration:

      iex> PeekAppSDK.Config.get_config()
      %{
        peek_app_secret: "default_secret",
        peek_app_id: "default_app_id",
        peek_api_url: "https://api.peek.com",
        peek_app_key: "default_app_key"
      }

  Note that `peek_api_url` and `peek_app_key` are always taken from the default
  `:peek_app_sdk` configuration, regardless of which application identifier is used.
  """
  @spec get_config(atom() | nil) :: map()
  def get_config(identifier \\ nil)

  def get_config(nil) do
    # Return the default configuration from :peek_app_sdk
    %{
      peek_app_secret: Application.get_env(:peek_app_sdk, :peek_app_secret),
      peek_app_id: Application.get_env(:peek_app_sdk, :peek_app_id),
      peek_api_url: Application.get_env(:peek_app_sdk, :peek_api_url, @default_peek_url),
      peek_app_key: Application.get_env(:peek_app_sdk, :peek_app_key)
    }
  end

  def get_config(identifier) when is_atom(identifier) do
    # Try to get configuration from the specified application
    peek_app_secret = Application.get_env(identifier, :peek_app_secret)
    peek_app_id = Application.get_env(identifier, :peek_app_id)

    if peek_app_secret && peek_app_id do
      %{
        peek_app_secret: peek_app_secret,
        peek_app_id: peek_app_id,
        peek_api_url: Application.get_env(:peek_app_sdk, :peek_api_url, @default_peek_url),
        peek_app_key: Application.get_env(:peek_app_sdk, :peek_app_key)
      }
    else
      # Fall back to default configuration if the specified application doesn't have the required config
      get_config(nil)
    end
  end
end
