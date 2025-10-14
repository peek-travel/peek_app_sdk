defmodule PeekAppSDK.Metrics.Client do
  alias PeekAppSDK.Config

  @moduledoc """
  Client for sending metrics to the Peek Pro metrics service.
  """

  @doc """
  Creates a Tesla client with the appropriate middleware configuration.
  """
  def client do
    middleware = [
      Tesla.Middleware.JSON,
      {Tesla.Middleware.Headers, [{"Content-Type", "application/json"}]},
      {Tesla.Middleware.Retry, delay: 500, max_retries: 10}
    ]

    Tesla.client(middleware)
  end

  def update_configuration_status(install_id, status, notes \\ nil, config_id \\ nil) do
    # Check for deprecated configuration when using the new update_configuration_status feature
    Config.check_deprecated_config!()

    body = %{
      status: status,
      notes: notes
    }

    config = Config.get_config(config_id)
    peek_app_key = config.peek_app_key
    peek_app_id = config.peek_app_id
    peek_api_base_url = config.peek_api_base_url

    url =
      "#{peek_api_base_url}/registry/installations/#{peek_app_id}/#{install_id}/configuration_status"

    case Tesla.put!(client(), url, body, headers: headers(install_id, config_id, peek_app_key)) do
      %Tesla.Env{status: 200} ->
        :ok

      %Tesla.Env{status: status, body: body} ->
        {:error, {status, body}}
    end
  end

  @doc """
  Tracks an event with the given event ID and payload.

  This function takes an event ID and a map of options and sends them directly to the API
  without any validation or transformation. The only required field in the options map is
  `eventId`, which is automatically added based on the first parameter.

  ## Parameters

    * `event_id` - The ID of the event to track
    * `payload` - A map of fields to include in the event payload

  ## Examples

      iex> PeekAppSDK.Metrics.Client.track("app.install", %{
      ...>   anonymousId: "partner-123",
      ...>   level: "info",
      ...>   usageDisplay: "New App Installs",
      ...>   usageDetails: "Partner Name",
      ...>   postMessage: "Partner Name installed"
      ...> })
      {:ok, %{...}}
  """
  def track(event_id, payload) do
    # Simply merge the event_id into the payload and send it
    payload =
      Map.merge(
        %{
          "eventId" => event_id,
          "level" => "info",
          "anonymousId" => "unknown"
        },
        payload
      )

    do_post!(payload)
  end

  @doc """
  Tracks an app installation event.

  ## Parameters

    * `external_refid` - The external reference ID for the partner
    * `name` - The name of the partner
    * `is_test` - Boolean indicating if this is a test installation

  ## Examples

      iex> PeekAppSDK.Metrics.Client.track_install("partner-123", "Partner Name", false)
      {:ok, %{...}}

  """
  def track_install(external_refid, name, is_test, opts \\ []) do
    post_message = if(Keyword.get(opts, :post_message, false), do: "#{name} installed")
    usage_display = if is_test, do: "New TEST App Installs", else: "New App Installs"

    do_post!(%{
      eventId: "app.install",
      level: "info",
      anonymousId: external_refid,
      usageDisplay: usage_display,
      usageDetails: name,
      postMessage: post_message,
      customFields: base_custom_fields(name, external_refid, is_test)
    })
  end

  @doc """
  Tracks an app uninstallation event.

  ## Parameters

    * `external_refid` - The external reference ID for the partner
    * `name` - The name of the partner
    * `is_test` - Boolean indicating if this is a test installation

  ## Examples

      iex> PeekAppSDK.Metrics.Client.track_uninstall("partner-123", "Partner Name", false)
      {:ok, %{...}}

  """
  def track_uninstall(external_refid, name, is_test, opts \\ []) do
    post_message = if(Keyword.get(opts, :post_message, false), do: "#{name} uninstalled")
    usage_display = if is_test, do: "New TEST App Uninstalls", else: "New App Uninstalls"

    do_post!(%{
      eventId: "app.uninstall",
      level: "info",
      anonymousId: external_refid,
      usageDisplay: usage_display,
      usageDetails: name,
      postMessage: post_message,
      customFields: base_custom_fields(name, external_refid, is_test)
    })
  end

  defp base_custom_fields(name, external_refid, is_test) do
    %{
      "partnerName" => name,
      "partnerExternalRefid" => external_refid,
      "partnerIsTest" => is_test
    }
  end

  defp event_url,
    do: "https://ahem.peeklabs.com/events/#{Application.fetch_env!(:peek_app_sdk, :peek_app_id)}"

  defp do_post!(body, _opts \\ []) do
    response = Tesla.post!(client(), event_url(), body)

    case response do
      %Tesla.Env{status: 202} ->
        {:ok, body}

      %Tesla.Env{status: status, body: body} ->
        {:error, {status, body}}
    end
  end

  defp headers(install_id, config_id, nil) do
    [x_peek_auth_header(install_id, config_id)]
  end

  defp headers(install_id, config_id, peek_app_key) do
    [
      x_peek_auth_header(install_id, config_id),
      {"pk-api-key", peek_app_key}
    ]
  end

  defp x_peek_auth_header(install_id, config_id),
    do:
      {"X-Peek-Auth",
       "Bearer #{PeekAppSDK.Token.new_for_app_installation!(install_id, nil, config_id)}"}
end
