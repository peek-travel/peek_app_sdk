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
      {Tesla.Middleware.Retry, delay: 500, max_retries: 10},
      {Tesla.Middleware.BaseUrl, "https://us.i.posthog.com"}
    ]

    Tesla.client(middleware)
  end

  def identify(%{name: partner_name, external_refid: partner_id, is_test: is_test, platform: platform}) do
    config = Config.get_config()
    posthog_key = config.posthog_key

    body = %{
      api_key: posthog_key,
      properties: %{"$set" => %{"name" => partner_name, "is_test" => is_test, "platform" => platform}},
      timestamp: DateTime.utc_now() |> DateTime.to_iso8601(),
      distinct_id: "#{platform}-#{partner_id}",
      event: "$set"
    }

    if posthog_key do
      Tesla.post!(client(), "/i/v0/e/", body)
    end
  end

  def track(%{name: partner_name, external_refid: partner_id, is_test: is_test, platform: platform}, event_id, payload) do
    config = Config.get_config()
    posthog_key = config.posthog_key
    app_id = config.peek_app_id
    distinct_id = "#{platform}-#{partner_id}"

    body = %{
      api_key: posthog_key,
      event: event_id,
      properties:
        Map.merge(payload, %{
          distinct_id: distinct_id,
          partner_id: partner_id,
          partner_name: partner_name,
          partner_is_test: is_test,
          app_slug: app_id,
          platform: platform
        })
    }

    if posthog_key do
      response = Tesla.post!(client(), "/capture", body)

      case response do
        %Tesla.Env{status: 200} ->
          {:ok, body}

        %Tesla.Env{status: status, body: body} ->
          {:error, {status, body}}
      end
    end
  end
end
