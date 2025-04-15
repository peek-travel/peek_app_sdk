defmodule PeekAppSDK.Health.Client do
  @moduledoc """
  Client for interacting with the Peek Health API.

  This module provides functions for tracking events and health metrics.
  """

  require Logger

  use Tesla

  alias PeekAppSDK.Config
  alias PeekAppSDK.Health.Models.EventPayload

  plug Tesla.Middleware.JSON

  @default_health_api_url "https://peek-labs-app-health-metrics.web.app"

  @doc """
  Tracks an event for a monitored application.

  ## Parameters

  * `monitored_app_id` - ID of the monitored application
  * `payload` - EventPayload struct containing event data
  * `config_id` - Optional configuration identifier

  ## Returns

  * `{:ok, response}` - If the event was successfully tracked
  * `{:error, reason}` - If there was an error tracking the event

  ## Examples

      iex> payload = %PeekAppSDK.Health.Models.EventPayload{
      ...>   event_id: "app.install",
      ...>   level: :info,
      ...>   anonymous_id: "anon-123456"
      ...> }
      iex> PeekAppSDK.Health.Client.track_event("app-123", payload)
      {:ok, %{success: true, message: "Event tracked successfully", event_id: "1625097600000_abc123"}}
  """
  @spec track_event(String.t(), EventPayload.t(), atom() | nil) ::
          {:ok, map()} | {:error, any()}
  def track_event(monitored_app_id, %EventPayload{} = payload, config_id \\ nil) do
    with :ok <- EventPayload.validate(payload) do
      config = Config.get_config(config_id)
      health_api_url = get_health_api_url(config)

      url = "#{health_api_url}/events/#{monitored_app_id}"
      body = EventPayload.to_api_map(payload)

      case request(method: :post, url: url, body: body, headers: headers(config)) do
        {:ok, %Tesla.Env{status: 200, body: body}} ->
          {:ok, process_response(body)}

        {:ok, %Tesla.Env{status: status, body: body}} ->
          error_message = extract_error_message(body)
          Logger.error("Health API error (#{status}): #{error_message}")
          {:error, {status, error_message}}

        {:error, reason} ->
          Logger.error("Health API request failed: #{inspect(reason)}")
          {:error, reason}
      end
    end
  end

  # Private functions

  defp get_health_api_url(config) do
    Application.get_env(:peek_app_sdk, :health_api_url) ||
      Map.get(config, :health_api_url, @default_health_api_url)
  end

  defp headers(config) do
    # Start with content type header
    headers = [{"content-type", "application/json"}]

    # Get health API key from config or application env
    health_api_key =
      Map.get(config, :health_api_key) ||
        Application.get_env(:peek_app_sdk, :health_api_key)

    # Add API key if configured
    case health_api_key do
      nil -> headers
      key -> [{"x-api-key", key} | headers]
    end
  end

  defp process_response(body) when is_map(body) do
    body
    |> Enum.map(fn
      {"success", v} -> {:success, v}
      {"message", v} -> {:message, v}
      {"eventId", v} -> {:event_id, v}
      {k, v} -> {String.to_atom(k), v}
    end)
    |> Map.new()
  end

  defp process_response(body), do: body

  defp extract_error_message(%{"error" => error}) when is_binary(error), do: error

  defp extract_error_message(%{"error" => %{"message" => message}}) when is_binary(message),
    do: message

  defp extract_error_message(%{"message" => message}) when is_binary(message), do: message
  defp extract_error_message(body) when is_map(body), do: inspect(body)
  defp extract_error_message(_), do: "Unknown error"
end
