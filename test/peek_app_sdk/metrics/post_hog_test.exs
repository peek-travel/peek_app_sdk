defmodule PeekAppSDK.Metrics.PostHogTest do
  use ExUnit.Case, async: false

  alias PeekAppSDK.Metrics.PostHog

  describe "PostHog.identify" do
    test "sends identify event to PostHog when posthog_key is configured" do
      prev = Application.get_env(:peek_app_sdk, :posthog_key)
      Application.put_env(:peek_app_sdk, :posthog_key, "ph_test_key")
      on_exit(fn -> Application.put_env(:peek_app_sdk, :posthog_key, prev) end)

      Tesla.Adapter.Finch
      |> Mimic.stub(:call, fn env, _opts ->
        send(self(), {:request, env.url, Jason.decode!(env.body)})
        {:ok, %Tesla.Env{status: 200}}
      end)

      partner = %{name: "Test Partner", external_refid: "partner-123", is_test: false, platform: "peek"}

      PostHog.identify(partner)

      assert_receive {:request, url, body}
      assert String.contains?(url, "/i/v0/e/")
      assert body["event"] == "$set"
      assert body["distinct_id"] == "peek-partner-123"
      assert body["properties"]["$set"]["name"] == "Test Partner"
      assert body["properties"]["$set"]["is_test"] == false
      assert body["properties"]["$set"]["platform"] == "peek"
    end

    test "does not send identify when posthog_key is not configured" do
      prev = Application.get_env(:peek_app_sdk, :posthog_key)
      Application.delete_env(:peek_app_sdk, :posthog_key)
      on_exit(fn -> Application.put_env(:peek_app_sdk, :posthog_key, prev) end)

      Tesla.Adapter.Finch
      |> Mimic.stub(:call, fn _env, _opts ->
        flunk("Should not make HTTP request when posthog_key is not configured")
      end)

      partner = %{name: "Test Partner", external_refid: "partner-123", is_test: false, platform: "peek"}

      # Should not raise or make HTTP request
      PostHog.identify(partner)
    end
  end

  describe "PostHog.track does not identify" do
    test "does not identify even on app.install (identify handled by Metrics.track_install)" do
      prev = Application.get_env(:peek_app_sdk, :posthog_key)
      Application.put_env(:peek_app_sdk, :posthog_key, "ph_test_key")
      on_exit(fn -> Application.put_env(:peek_app_sdk, :posthog_key, prev) end)

      Tesla.Adapter.Finch
      |> Mimic.stub(:call, fn env, _opts ->
        send(self(), {:request, env.url, Jason.decode!(env.body)})
        {:ok, %Tesla.Env{status: 200}}
      end)

      partner = %{name: "Partner Name", external_refid: "1234", is_test: true, platform: "peek"}
      event_id = "app.install"

      assert {:ok, _} = PostHog.track(partner, event_id, %{foo: "bar"})

      assert_receive {:request, url, body}
      assert String.contains?(url, "/capture")
      assert body["event"] == event_id
      assert body["properties"]["platform"] == "peek"
      refute_receive {:request, _, _}
    end

    test "does not identify for non-install events" do
      prev = Application.get_env(:peek_app_sdk, :posthog_key)
      Application.put_env(:peek_app_sdk, :posthog_key, "ph_test_key")
      on_exit(fn -> Application.put_env(:peek_app_sdk, :posthog_key, prev) end)

      Tesla.Adapter.Finch
      |> Mimic.stub(:call, fn env, _opts ->
        send(self(), {:request, env.url, Jason.decode!(env.body)})
        {:ok, %Tesla.Env{status: 200}}
      end)

      partner = %{name: "Partner Name", external_refid: "1234", is_test: false, platform: "peek"}
      event_id = "test.event"

      assert {:ok, _} = PostHog.track(partner, event_id, %{foo: "bar"})

      assert_receive {:request, url, body}
      assert String.contains?(url, "/capture")
      assert body["event"] == event_id
      assert body["properties"]["platform"] == "peek"

      refute_receive {:request, _, _}
    end

    test "does not send track when posthog_key is not configured" do
      prev = Application.get_env(:peek_app_sdk, :posthog_key)
      Application.delete_env(:peek_app_sdk, :posthog_key)
      on_exit(fn -> Application.put_env(:peek_app_sdk, :posthog_key, prev) end)

      Tesla.Adapter.Finch
      |> Mimic.stub(:call, fn _env, _opts ->
        flunk("Should not make HTTP request when posthog_key is not configured")
      end)

      partner = %{name: "Partner Name", external_refid: "1234", is_test: false, platform: "peek"}
      event_id = "test.event"

      # Should not raise or make HTTP request
      PostHog.track(partner, event_id, %{foo: "bar"})
    end

    test "handles error response from PostHog API" do
      prev = Application.get_env(:peek_app_sdk, :posthog_key)
      Application.put_env(:peek_app_sdk, :posthog_key, "ph_test_key")
      on_exit(fn -> Application.put_env(:peek_app_sdk, :posthog_key, prev) end)

      Tesla.Adapter.Finch
      |> Mimic.stub(:call, fn _env, _opts ->
        {:ok, %Tesla.Env{status: 500, body: %{error: "Internal server error"}}}
      end)

      partner = %{name: "Partner Name", external_refid: "1234", is_test: false, platform: "peek"}
      event_id = "test.event"

      assert {:error, {500, %{error: "Internal server error"}}} =
               PostHog.track(partner, event_id, %{foo: "bar"})
    end
  end
end
