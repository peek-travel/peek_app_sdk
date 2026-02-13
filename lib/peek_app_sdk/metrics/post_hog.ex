defmodule PeekAppSDK.Metrics.PostHog do
  alias PeekAppSDK.Config

  @moduledoc """
  Client for sending metrics to the Peek Pro metrics service.
  """

  @default_platform "peek"

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

  @doc """
  Extracts platform from partner map, defaulting to "peek" if not present.
  """
  def get_platform(%{platform: platform}), do: platform
  def get_platform(_), do: @default_platform

  @doc """
  Builds the distinct_id for PostHog. Only prefixes for non-peek platforms
  to maintain backward compatibility with existing peek partners.
  """
  def build_distinct_id(partner_id, platform), do: "#{platform}-#{partner_id}"

  def identify(%{name: partner_name, external_refid: partner_id, is_test: is_test} = partner) do
    config = Config.get_config()
    posthog_key = config.posthog_key
    platform = get_platform(partner)
    distinct_id = build_distinct_id(partner_id, platform)

    body = %{
      api_key: posthog_key,
      properties: %{"$set" => %{"name" => partner_name, "is_test" => is_test, "platform" => platform}},
      timestamp: DateTime.utc_now() |> DateTime.to_iso8601(),
      distinct_id: distinct_id,
      event: "$set"
    }

    if posthog_key do
      Tesla.post!(client(), "/i/v0/e/", body)
    end
  end

  def track(%{name: partner_name, external_refid: partner_id, is_test: is_test} = partner, event_id, payload) do
    config = Config.get_config()
    posthog_key = config.posthog_key
    app_id = config.peek_app_id
    platform = get_platform(partner)
    distinct_id = build_distinct_id(partner_id, platform)

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
