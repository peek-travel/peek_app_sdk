defmodule PeekAppSDK.Metrics.PostHog do
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

  def track(%{name: partner_name, external_refid: partner_id} = partner, event_id, payload) do
    config = Config.get_config()
    posthog_key = config.posthog_key
    app_id = config.peek_app_id
    url = "https://us.i.posthog.com/capture"

    body = %{
      api_key: posthog_key,
      event: event_id,
      properties:
        Map.merge(payload, %{
          distinct_id: partner_id,
          partner_id: partner_id,
          partner_name: partner_name,
          partner_is_test: partner.is_test,
          app_slug: app_id,
          "$process_person_profile": false
        })
    }

    if posthog_key do
      response = Tesla.post!(client(), url, body)

      case response do
        %Tesla.Env{status: 200} ->
          {:ok, body}

        %Tesla.Env{status: status, body: body} ->
          {:error, {status, body}}
      end
    end
  end
end
