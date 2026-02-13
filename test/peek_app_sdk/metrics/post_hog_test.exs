defmodule PeekAppSDK.Metrics.PostHogTest do
  use ExUnit.Case, async: false

  alias PeekAppSDK.Metrics.PostHog

  describe "get_platform/1" do
    test "returns platform when present in partner map" do
      assert PostHog.get_platform(%{platform: "cng"}) == "cng"
      assert PostHog.get_platform(%{platform: "acme"}) == "acme"
      assert PostHog.get_platform(%{platform: "peek"}) == "peek"
    end

    test "defaults to peek when platform not present" do
      assert PostHog.get_platform(%{name: "Test"}) == "peek"
      assert PostHog.get_platform(%{}) == "peek"
    end
  end

  describe "build_distinct_id/2" do
    test "prefixes distinct_id with platform" do
      assert PostHog.build_distinct_id("partner-123", "peek") == "peek-partner-123"
      assert PostHog.build_distinct_id("partner-123", "cng") == "cng-partner-123"
      assert PostHog.build_distinct_id("partner-123", "acme") == "acme-partner-123"
    end
  end

  describe "PostHog.identify" do
    test "sends identify event with peek platform" do
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

    test "sends identify event with cng platform (prefixed)" do
      prev = Application.get_env(:peek_app_sdk, :posthog_key)
      Application.put_env(:peek_app_sdk, :posthog_key, "ph_test_key")
      on_exit(fn -> Application.put_env(:peek_app_sdk, :posthog_key, prev) end)

      Tesla.Adapter.Finch
      |> Mimic.stub(:call, fn env, _opts ->
        send(self(), {:request, env.url, Jason.decode!(env.body)})
        {:ok, %Tesla.Env{status: 200}}
      end)

      partner = %{name: "CNG Partner", external_refid: "partner-456", is_test: false, platform: "cng"}

      PostHog.identify(partner)

      assert_receive {:request, _url, body}
      assert body["distinct_id"] == "cng-partner-456"
      assert body["properties"]["$set"]["platform"] == "cng"
    end

    test "defaults to peek platform when not provided" do
      prev = Application.get_env(:peek_app_sdk, :posthog_key)
      Application.put_env(:peek_app_sdk, :posthog_key, "ph_test_key")
      on_exit(fn -> Application.put_env(:peek_app_sdk, :posthog_key, prev) end)

      Tesla.Adapter.Finch
      |> Mimic.stub(:call, fn env, _opts ->
        send(self(), {:request, env.url, Jason.decode!(env.body)})
        {:ok, %Tesla.Env{status: 200}}
      end)

      # Partner without platform field
      partner = %{name: "Test Partner", external_refid: "partner-123", is_test: false}

      PostHog.identify(partner)

      assert_receive {:request, _url, body}
      assert body["distinct_id"] == "peek-partner-123"
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

      partner = %{name: "Test Partner", external_refid: "partner-123", is_test: false}

      # Should not raise or make HTTP request
      PostHog.identify(partner)
    end
  end

  describe "PostHog.track" do
    test "tracks with peek platform" do
      prev = Application.get_env(:peek_app_sdk, :posthog_key)
      Application.put_env(:peek_app_sdk, :posthog_key, "ph_test_key")
      on_exit(fn -> Application.put_env(:peek_app_sdk, :posthog_key, prev) end)

      Tesla.Adapter.Finch
      |> Mimic.stub(:call, fn env, _opts ->
        send(self(), {:request, env.url, Jason.decode!(env.body)})
        {:ok, %Tesla.Env{status: 200}}
      end)

      partner = %{name: "Partner Name", external_refid: "1234", is_test: true, platform: "peek"}

      assert {:ok, _} = PostHog.track(partner, "app.install", %{foo: "bar"})

      assert_receive {:request, url, body}
      assert String.contains?(url, "/capture")
      assert body["properties"]["distinct_id"] == "peek-1234"
      assert body["properties"]["platform"] == "peek"
    end

    test "tracks with cng platform" do
      prev = Application.get_env(:peek_app_sdk, :posthog_key)
      Application.put_env(:peek_app_sdk, :posthog_key, "ph_test_key")
      on_exit(fn -> Application.put_env(:peek_app_sdk, :posthog_key, prev) end)

      Tesla.Adapter.Finch
      |> Mimic.stub(:call, fn env, _opts ->
        send(self(), {:request, env.url, Jason.decode!(env.body)})
        {:ok, %Tesla.Env{status: 200}}
      end)

      partner = %{name: "CNG Partner", external_refid: "5678", is_test: false, platform: "cng"}

      assert {:ok, _} = PostHog.track(partner, "order.created", %{amount: 100})

      assert_receive {:request, _url, body}
      assert body["properties"]["distinct_id"] == "cng-5678"
      assert body["properties"]["platform"] == "cng"
    end

    test "defaults to peek platform when not provided" do
      prev = Application.get_env(:peek_app_sdk, :posthog_key)
      Application.put_env(:peek_app_sdk, :posthog_key, "ph_test_key")
      on_exit(fn -> Application.put_env(:peek_app_sdk, :posthog_key, prev) end)

      Tesla.Adapter.Finch
      |> Mimic.stub(:call, fn env, _opts ->
        send(self(), {:request, env.url, Jason.decode!(env.body)})
        {:ok, %Tesla.Env{status: 200}}
      end)

      # Partner without platform field
      partner = %{name: "Partner Name", external_refid: "1234", is_test: false}

      assert {:ok, _} = PostHog.track(partner, "test.event", %{foo: "bar"})

      assert_receive {:request, _url, body}
      assert body["properties"]["distinct_id"] == "peek-1234"
      assert body["properties"]["platform"] == "peek"
    end

    test "does not send track when posthog_key is not configured" do
      prev = Application.get_env(:peek_app_sdk, :posthog_key)
      Application.delete_env(:peek_app_sdk, :posthog_key)
      on_exit(fn -> Application.put_env(:peek_app_sdk, :posthog_key, prev) end)

      Tesla.Adapter.Finch
      |> Mimic.stub(:call, fn _env, _opts ->
        flunk("Should not make HTTP request when posthog_key is not configured")
      end)

      partner = %{name: "Partner Name", external_refid: "1234", is_test: false}

      # Should not raise or make HTTP request
      PostHog.track(partner, "test.event", %{foo: "bar"})
    end

    test "handles error response from PostHog API" do
      prev = Application.get_env(:peek_app_sdk, :posthog_key)
      Application.put_env(:peek_app_sdk, :posthog_key, "ph_test_key")
      on_exit(fn -> Application.put_env(:peek_app_sdk, :posthog_key, prev) end)

      Tesla.Adapter.Finch
      |> Mimic.stub(:call, fn _env, _opts ->
        {:ok, %Tesla.Env{status: 500, body: %{error: "Internal server error"}}}
      end)

      partner = %{name: "Partner Name", external_refid: "1234", is_test: false}

      assert {:error, {500, %{error: "Internal server error"}}} =
               PostHog.track(partner, "test.event", %{foo: "bar"})
    end
  end
end
