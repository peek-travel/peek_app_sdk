defmodule PeekAppSDK.Health.Models.EventContextTest do
  use ExUnit.Case, async: true

  alias PeekAppSDK.Health.Models.EventContext

  describe "to_api_map/1" do
    test "converts struct to API map with camelCase keys" do
      context = %EventContext{
        channel: "web",
        user_agent: "Mozilla/5.0",
        session_id: "sess-123456",
        timezone: "America/New_York",
        ip: "192.168.1.1",
        page: "/dashboard",
        screen: %{height: 1080, width: 1920}
      }

      api_map = EventContext.to_api_map(context)

      assert api_map["channel"] == "web"
      assert api_map["userAgent"] == "Mozilla/5.0"
      assert api_map["sessionId"] == "sess-123456"
      assert api_map["timezone"] == "America/New_York"
      assert api_map["ip"] == "192.168.1.1"
      assert api_map["page"] == "/dashboard"
      assert api_map["screen"]["Height"] == 1080
      assert api_map["screen"]["Width"] == 1920
    end

    test "excludes nil values" do
      context = %EventContext{
        channel: "web",
        user_agent: "Mozilla/5.0"
      }

      api_map = EventContext.to_api_map(context)

      assert api_map["channel"] == "web"
      assert api_map["userAgent"] == "Mozilla/5.0"
      refute Map.has_key?(api_map, "sessionId")
      refute Map.has_key?(api_map, "screen")
    end
  end

  describe "from_map/1" do
    test "converts map to EventContext struct" do
      map = %{
        "channel" => "web",
        "userAgent" => "Mozilla/5.0",
        "sessionId" => "sess-123456",
        "timezone" => "America/New_York",
        "ip" => "192.168.1.1",
        "page" => "/dashboard",
        "screen" => %{
          "Height" => 1080,
          "Width" => 1920
        }
      }

      context = EventContext.from_map(map)

      assert context.channel == "web"
      assert context.user_agent == "Mozilla/5.0"
      assert context.session_id == "sess-123456"
      assert context.timezone == "America/New_York"
      assert context.ip == "192.168.1.1"
      assert context.page == "/dashboard"
      assert context.screen.height == 1080
      assert context.screen.width == 1920
    end

    test "handles missing screen" do
      map = %{
        "channel" => "web",
        "userAgent" => "Mozilla/5.0"
      }

      context = EventContext.from_map(map)

      assert context.channel == "web"
      assert context.user_agent == "Mozilla/5.0"
      assert context.screen == nil
    end
  end
end
