defmodule PeekAppSDK.InstallationsApi do
  @moduledoc """
  Client for the app-registry `/installations-api/:app_id` routes — endpoints an
  installed app calls directly about its own install (not proxied through an
  `ExtendableInstall`).
  """

  alias PeekAppSDK.Client
  alias PeekAppSDK.Config

  @doc """
  Updates the configuration status for an app installation.

  ## Examples

      iex> PeekAppSDK.InstallationsApi.update_configuration_status("install_id", "configured")
      :ok
  """
  @spec update_configuration_status(String.t(), String.t(), String.t() | nil, atom() | nil) ::
          :ok | {:error, {integer(), any()}}
  def update_configuration_status(install_id, status, notes \\ nil, config_id \\ nil) do
    Config.check_deprecated_config!()

    body = %{status: status, notes: notes}

    case request(:put, "configuration_status/#{install_id}", install_id, body, config_id) do
      {:ok, %Tesla.Env{status: 200}} -> :ok
      {:ok, %Tesla.Env{status: status, body: body}} -> {:error, {status, body}}
    end
  end

  @doc """
  Syncs a customizations payload to the platform that owns the given install.

  The platform's response body is returned unchanged, success or error — check
  it for details when `status` is outside the 2xx range.

  ## Examples

      iex> PeekAppSDK.InstallationsApi.customize_installation("install_id", %{"foo" => "bar"})
      {:ok, %{"foo" => "bar"}}
  """
  @spec customize_installation(String.t(), map(), atom() | nil) ::
          {:ok, any()} | {:error, {integer(), any()}}
  def customize_installation(install_id, payload, config_id \\ nil) do
    case request(:post, "customizations", install_id, payload, config_id) do
      {:ok, %Tesla.Env{status: status, body: body}} when status in 200..299 -> {:ok, body}
      {:ok, %Tesla.Env{status: status, body: body}} -> {:error, {status, body}}
    end
  end

  @doc """
  Fetches the customizations currently persisted for the given install.

  ## Examples

      iex> PeekAppSDK.InstallationsApi.get_customizations("install_id")
      {:ok, %{customizations: %{"some_extendable_slug@v1" => %{"foo" => "bar"}}}}
  """
  @spec get_customizations(String.t(), atom() | nil) ::
          {:ok, any()} | {:error, {integer(), any()}}
  def get_customizations(install_id, config_id \\ nil) do
    case request(:get, "customizations", install_id, %{}, config_id) do
      {:ok, %Tesla.Env{status: status, body: body}} when status in 200..299 -> {:ok, body}
      {:ok, %Tesla.Env{status: status, body: body}} -> {:error, {status, body}}
    end
  end

  defp request(method, path, install_id, body, config_id) do
    config = Config.get_config(config_id)

    url = "#{config.peek_api_base_url}/installations-api/#{config.peek_app_id}/#{path}"

    Tesla.request(Client.client(),
      method: method,
      url: url,
      body: body,
      headers: Client.headers(install_id, config_id, config.peek_api_key)
    )
  end
end
