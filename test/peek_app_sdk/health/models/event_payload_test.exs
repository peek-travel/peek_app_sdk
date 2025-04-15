defmodule PeekAppSDK.Health.Models.EventPayloadTest do
  use ExUnit.Case, async: true

  alias PeekAppSDK.Health.Models.EventPayload
  alias PeekAppSDK.Health.Models.EventContext

  describe "validate/1" do
    test "returns :ok for valid payload" do
      payload = %EventPayload{
        event_id: "app.install",
        level: :info,
        anonymous_id: "anon-123456"
      }

      assert :ok = EventPayload.validate(payload)
    end

    test "returns error for missing event_id" do
      payload = %EventPayload{
        level: :info,
        anonymous_id: "anon-123456"
      }

      assert {:error, "Missing required field: event_id"} = EventPayload.validate(payload)
    end

    test "returns error for missing level" do
      payload = %EventPayload{
        event_id: "app.install",
        anonymous_id: "anon-123456"
      }

      assert {:error, "Missing required field: level"} = EventPayload.validate(payload)
    end

    test "returns error for invalid level" do
      payload = %EventPayload{
        event_id: "app.install",
        level: :warning,
        anonymous_id: "anon-123456"
      }

      assert {:error, "Invalid level: :warning. Must be :info or :error"} = EventPayload.validate(payload)
    end

    test "returns error for missing anonymous_id" do
      payload = %EventPayload{
        event_id: "app.install",
        level: :info
      }

      assert {:error, "Missing required field: anonymous_id"} = EventPayload.validate(payload)
    end
  end

  describe "to_api_map/1" do
    test "converts struct to API map with camelCase keys" do
      context = %EventContext{
        channel: "web",
        user_agent: "Mozilla/5.0",
        screen: %{height: 1080, width: 1920}
      }

      payload = %EventPayload{
        event_id: "app.install",
        level: :info,
        anonymous_id: "anon-123456",
        user_id: "user-789012",
        idempotency_key: "idem-345678",
        context: context,
        usage_display: "New Installation",
        usage_details: "User installed the app from the marketplace",
        post_message: "A new user has installed the app",
        custom_fields: %{plan: "premium", referrer: "partner_site"}
      }

      api_map = EventPayload.to_api_map(payload)

      assert api_map["eventId"] == "app.install"
      assert api_map["level"] == "info"
      assert api_map["anonymousId"] == "anon-123456"
      assert api_map["userId"] == "user-789012"
      assert api_map["idempotencyKey"] == "idem-345678"
      assert api_map["usageDisplay"] == "New Installation"
      assert api_map["usageDetails"] == "User installed the app from the marketplace"
      assert api_map["postMessage"] == "A new user has installed the app"
      assert api_map["customFields"] == %{plan: "premium", referrer: "partner_site"}
      
      assert api_map["context"]["channel"] == "web"
      assert api_map["context"]["userAgent"] == "Mozilla/5.0"
      assert api_map["context"]["screen"]["Height"] == 1080
      assert api_map["context"]["screen"]["Width"] == 1920
    end

    test "excludes nil values" do
      payload = %EventPayload{
        event_id: "app.install",
        level: :info,
        anonymous_id: "anon-123456"
      }

      api_map = EventPayload.to_api_map(payload)

      assert api_map["eventId"] == "app.install"
      assert api_map["level"] == "info"
      assert api_map["anonymousId"] == "anon-123456"
      refute Map.has_key?(api_map, "userId")
      refute Map.has_key?(api_map, "context")
    end
  end

  describe "from_map/1" do
    test "converts map to EventPayload struct" do
      map = %{
        "eventId" => "app.install",
        "level" => "info",
        "anonymousId" => "anon-123456",
        "userId" => "user-789012",
        "idempotencyKey" => "idem-345678",
        "context" => %{
          "channel" => "web",
          "userAgent" => "Mozilla/5.0",
          "screen" => %{
            "Height" => 1080,
            "Width" => 1920
          }
        },
        "usageDisplay" => "New Installation",
        "usageDetails" => "User installed the app from the marketplace",
        "postMessage" => "A new user has installed the app",
        "customFields" => %{
          "plan" => "premium",
          "referrer" => "partner_site"
        }
      }

      payload = EventPayload.from_map(map)

      assert payload.event_id == "app.install"
      assert payload.level == :info
      assert payload.anonymous_id == "anon-123456"
      assert payload.user_id == "user-789012"
      assert payload.idempotency_key == "idem-345678"
      assert payload.usage_display == "New Installation"
      assert payload.usage_details == "User installed the app from the marketplace"
      assert payload.post_message == "A new user has installed the app"
      assert payload.custom_fields == %{
        "plan" => "premium",
        "referrer" => "partner_site"
      }
      
      assert payload.context.channel == "web"
      assert payload.context.user_agent == "Mozilla/5.0"
      assert payload.context.screen.height == 1080
      assert payload.context.screen.width == 1920
    end
  end
end
