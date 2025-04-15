defmodule PeekAppSDK.HealthTest do
  use ExUnit.Case, async: true
  import Mox

  alias PeekAppSDK.Health
  alias PeekAppSDK.Health.Models.EventPayload
  alias PeekAppSDK.Health.Models.EventContext

  setup :verify_on_exit!

  describe "track_event/3" do
    test "delegates to Client.track_event/3 with default config" do
      monitored_app_id = "test-app-123"

      payload = %EventPayload{
        event_id: "app.install",
        level: :info,
        anonymous_id: "anon-123456"
      }

      response_data = %{
        "success" => true,
        "message" => "Event tracked successfully",
        "eventId" => "1625097600000_abc123"
      }

      expect(PeekAppSDK.MockTeslaClient, :call, fn _env, _opts ->
        {:ok, %Tesla.Env{status: 200, body: response_data}}
      end)

      assert {:ok, result} = Health.track_event(monitored_app_id, payload)
      assert result.success == true
      assert result.message == "Event tracked successfully"
      assert result.event_id == "1625097600000_abc123"
    end

    test "delegates to Client.track_event/3 with atom config_id" do
      monitored_app_id = "test-app-123"

      payload = %EventPayload{
        event_id: "app.install",
        level: :info,
        anonymous_id: "anon-123456"
      }

      response_data = %{
        "success" => true,
        "message" => "Event tracked successfully",
        "eventId" => "1625097600000_abc123"
      }

      expect(PeekAppSDK.MockTeslaClient, :call, fn _env, _opts ->
        {:ok, %Tesla.Env{status: 200, body: response_data}}
      end)

      assert {:ok, _result} = Health.track_event(monitored_app_id, payload, :project_name)
    end
  end

  describe "new_event_payload/1" do
    test "creates an EventPayload struct from a map" do
      attrs = %{
        event_id: "app.install",
        level: :info,
        anonymous_id: "anon-123456",
        context: %{
          channel: "web",
          user_agent: "Mozilla/5.0"
        }
      }

      payload = Health.new_event_payload(attrs)

      assert %EventPayload{} = payload
      assert payload.event_id == "app.install"
      assert payload.level == :info
      assert payload.anonymous_id == "anon-123456"
      assert %EventContext{} = payload.context
      assert payload.context.channel == "web"
      assert payload.context.user_agent == "Mozilla/5.0"
    end
  end

  describe "new_event_context/1" do
    test "creates an EventContext struct from a map" do
      attrs = %{
        channel: "web",
        user_agent: "Mozilla/5.0",
        screen: %{height: 1080, width: 1920}
      }

      context = Health.new_event_context(attrs)

      assert %EventContext{} = context
      assert context.channel == "web"
      assert context.user_agent == "Mozilla/5.0"
      assert context.screen.height == 1080
      assert context.screen.width == 1920
    end
  end

  describe "track_info_event/5" do
    test "creates an info-level event payload and tracks it" do
      monitored_app_id = "test-app-123"
      event_id = "app.install"
      anonymous_id = "anon-123456"

      # Use a simple map without context for this test
      opts = %{user_id: "user-789012"}

      response_data = %{
        "success" => true,
        "message" => "Event tracked successfully",
        "eventId" => "1625097600000_abc123"
      }

      expect(PeekAppSDK.MockTeslaClient, :call, fn env, _opts ->
        body = Jason.decode!(env.body)

        assert body["eventId"] == "app.install"
        assert body["level"] == "info"
        assert body["anonymousId"] == "anon-123456"
        assert body["userId"] == "user-789012"
        # No context in this test

        {:ok, %Tesla.Env{status: 200, body: response_data}}
      end)

      assert {:ok, _result} =
               Health.track_info_event(monitored_app_id, event_id, anonymous_id, opts)
    end
  end

  describe "track_error_event/5" do
    test "creates an error-level event payload and tracks it" do
      monitored_app_id = "test-app-123"
      event_id = "app.error"
      anonymous_id = "anon-123456"

      # Use a simple map without context for this test
      opts = %{user_id: "user-789012"}

      response_data = %{
        "success" => true,
        "message" => "Event tracked successfully",
        "eventId" => "1625097600000_abc123"
      }

      expect(PeekAppSDK.MockTeslaClient, :call, fn env, _opts ->
        body = Jason.decode!(env.body)

        assert body["eventId"] == "app.error"
        assert body["level"] == "error"
        assert body["anonymousId"] == "anon-123456"
        assert body["userId"] == "user-789012"
        # No context in this test

        {:ok, %Tesla.Env{status: 200, body: response_data}}
      end)

      assert {:ok, _result} =
               Health.track_error_event(monitored_app_id, event_id, anonymous_id, opts)
    end
  end
end
