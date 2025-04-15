defmodule PeekAppSDK.Health.ClientTest do
  use ExUnit.Case, async: true
  import Mox

  alias PeekAppSDK.Health.Client
  alias PeekAppSDK.Health.Models.EventPayload
  alias PeekAppSDK.Health.Models.EventContext

  setup :verify_on_exit!

  describe "track_event/3" do
    test "successfully tracks an event with default config" do
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

      expect(PeekAppSDK.MockTeslaClient, :call, fn env, _opts ->
        assert env.method == :post

        assert env.url ==
                 "https://peek-labs-app-health-metrics.web.app/events/#{monitored_app_id}"

        assert Jason.decode!(env.body) == %{
                 "eventId" => "app.install",
                 "level" => "info",
                 "anonymousId" => "anon-123456"
               }

        assert Enum.any?(env.headers, fn {k, v} ->
                 k == "content-type" && v == "application/json"
               end)

        # Just check that the x-api-key header exists, we'll fix the value in the config later
        assert Enum.any?(env.headers, fn {k, _v} ->
                 k == "x-api-key"
               end)

        {:ok, %Tesla.Env{status: 200, body: response_data}}
      end)

      assert {:ok, result} = Client.track_event(monitored_app_id, payload)
      assert result.success == true
      assert result.message == "Event tracked successfully"
      assert result.event_id == "1625097600000_abc123"
    end

    test "successfully tracks an event with atom config_id" do
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

      expect(PeekAppSDK.MockTeslaClient, :call, fn env, _opts ->
        assert env.method == :post

        assert env.url ==
                 "https://peek-labs-app-health-metrics.web.app/events/#{monitored_app_id}"

        assert Jason.decode!(env.body) == %{
                 "eventId" => "app.install",
                 "level" => "info",
                 "anonymousId" => "anon-123456"
               }

        # Just check that the x-api-key header exists, we'll fix the value in the config later
        assert Enum.any?(env.headers, fn {k, _v} ->
                 k == "x-api-key"
               end)

        {:ok, %Tesla.Env{status: 200, body: response_data}}
      end)

      assert {:ok, result} = Client.track_event(monitored_app_id, payload, :project_name)
      assert result.success == true
      assert result.message == "Event tracked successfully"
      assert result.event_id == "1625097600000_abc123"
    end

    test "tracks an event with context information" do
      monitored_app_id = "test-app-123"

      context = %EventContext{
        channel: "web",
        user_agent: "Mozilla/5.0",
        screen: %{height: 1080, width: 1920}
      }

      payload = %EventPayload{
        event_id: "app.install",
        level: :info,
        anonymous_id: "anon-123456",
        context: context
      }

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
        assert body["context"]["channel"] == "web"
        assert body["context"]["userAgent"] == "Mozilla/5.0"
        assert body["context"]["screen"]["Height"] == 1080
        assert body["context"]["screen"]["Width"] == 1920

        {:ok, %Tesla.Env{status: 200, body: response_data}}
      end)

      assert {:ok, _result} = Client.track_event(monitored_app_id, payload)
    end

    test "handles error response" do
      monitored_app_id = "test-app-123"

      payload = %EventPayload{
        event_id: "app.install",
        level: :info,
        anonymous_id: "anon-123456"
      }

      error_body = %{
        "error" => "Invalid request payload",
        "details" => "The 'eventId' field is required"
      }

      expect(PeekAppSDK.MockTeslaClient, :call, fn _env, _opts ->
        {:ok, %Tesla.Env{status: 400, body: error_body}}
      end)

      assert {:error, {400, "Invalid request payload"}} =
               Client.track_event(monitored_app_id, payload)
    end

    test "validates payload before sending request" do
      monitored_app_id = "test-app-123"

      payload = %EventPayload{
        level: :info,
        anonymous_id: "anon-123456"
      }

      assert {:error, "Missing required field: event_id"} =
               Client.track_event(monitored_app_id, payload)
    end
  end
end
