defmodule PeekAppSDK.MetricsTest do
  use ExUnit.Case, async: false

  alias PeekAppSDK.Metrics

  describe "track_install/4" do
    test "delegates to PeekAppSDK.Metrics.Client.track_install/4" do
      external_refid = "partner-123"
      name = "Partner Name"
      is_test = false
      opts = [post_message: true]

      Tesla.Adapter.Finch
      |> Mimic.stub(:call, fn env, _opts ->
        assert env.method == :post

        payload = Jason.decode!(env.body)
        assert payload["eventId"] == "app.install"
        assert payload["anonymousId"] == external_refid
        assert payload["usageDetails"] == name
        assert payload["customFields"]["partnerIsTest"] == is_test

        {:ok, %Tesla.Env{status: 202}}
      end)

      assert {:ok, _} = Metrics.track_install(external_refid, name, is_test, opts)
    end

    test "delegates to PeekAppSDK.Metrics.Client.track_install/3 with default opts" do
      external_refid = "partner-456"
      name = "Another Partner"
      is_test = true

      Tesla.Adapter.Finch
      |> Mimic.stub(:call, fn env, _opts ->
        assert env.method == :post

        payload = Jason.decode!(env.body)
        assert payload["eventId"] == "app.install"
        assert payload["anonymousId"] == external_refid
        assert payload["usageDetails"] == name
        assert payload["customFields"]["partnerIsTest"] == is_test

        {:ok, %Tesla.Env{status: 202}}
      end)

      assert {:ok, _} = Metrics.track_install(external_refid, name, is_test)
    end
  end

  describe "track_uninstall/4" do
    test "delegates to PeekAppSDK.Metrics.Client.track_uninstall/4" do
      external_refid = "partner-789"
      name = "Test Partner"
      is_test = false
      opts = [post_message: true]

      Tesla.Adapter.Finch
      |> Mimic.stub(:call, fn env, _opts ->
        assert env.method == :post

        payload = Jason.decode!(env.body)
        assert payload["eventId"] == "app.uninstall"
        assert payload["anonymousId"] == external_refid
        assert payload["usageDetails"] == name
        assert payload["customFields"]["partnerIsTest"] == is_test

        {:ok, %Tesla.Env{status: 202}}
      end)

      assert {:ok, _} = Metrics.track_uninstall(external_refid, name, is_test, opts)
    end

    test "delegates to PeekAppSDK.Metrics.Client.track_uninstall/3 with default opts" do
      external_refid = "partner-101"
      name = "Final Partner"
      is_test = true

      Tesla.Adapter.Finch
      |> Mimic.stub(:call, fn env, _opts ->
        assert env.method == :post

        payload = Jason.decode!(env.body)
        assert payload["eventId"] == "app.uninstall"
        assert payload["anonymousId"] == external_refid
        assert payload["usageDetails"] == name
        assert payload["customFields"]["partnerIsTest"] == is_test

        {:ok, %Tesla.Env{status: 202}}
      end)

      assert {:ok, _} = Metrics.track_uninstall(external_refid, name, is_test)
    end
  end

  describe "track/2" do
    test "delegates to PeekAppSDK.Metrics.Client.track/2" do
      event_id = "custom.event"

      payload = %{
        anonymousId: "user-123",
        level: "info",
        customField: "test value"
      }

      Tesla.Adapter.Finch
      |> Mimic.stub(:call, fn env, _opts ->
        assert env.method == :post

        sent_payload = Jason.decode!(env.body)
        assert sent_payload["eventId"] == event_id
        assert sent_payload["anonymousId"] == "user-123"
        assert sent_payload["level"] == "info"
        assert sent_payload["customField"] == "test value"

        {:ok, %Tesla.Env{status: 202}}
      end)

      assert {:ok, _} = Metrics.track(event_id, payload)
    end
  end

  describe "update_configuration_status/3" do
    test "delegates to PeekAppSDK.Metrics.Client.update_configuration_status/4" do
      install_id = "test_install_123"
      status = "configured"
      notes = "All set up"

      Tesla.Adapter.Finch
      |> Mimic.stub(:call, fn env, _opts ->
        assert env.method == :put
        assert String.contains?(env.url, install_id)

        {:ok, %Tesla.Env{status: 200}}
      end)

      assert :ok = Metrics.update_configuration_status(install_id, status, notes)
    end
  end

  describe "track_install/2 with partner map" do
    test "calls track_install/4, identify, and track for PostHog" do
      prev = Application.get_env(:peek_app_sdk, :posthog_key)
      Application.put_env(:peek_app_sdk, :posthog_key, "ph_test_key")
      on_exit(fn -> Application.put_env(:peek_app_sdk, :posthog_key, prev) end)

      Tesla.Adapter.Finch
      |> Mimic.stub(:call, fn env, _opts ->
        send(self(), {:request, env.url, Jason.decode!(env.body)})

        if String.contains?(env.url, "ahem.peeklabs.com/events/") do
          {:ok, %Tesla.Env{status: 202}}
        else
          {:ok, %Tesla.Env{status: 200}}
        end
      end)

      partner = %{external_refid: "p-1", name: "Partner Name", is_test: false, platform: "peek"}

      assert {:ok, _} = PeekAppSDK.Metrics.track_install(partner, [])

      assert_receive {:request, url1, _}
      assert String.contains?(url1, "ahem.peeklabs.com/events/")
      assert_receive {:request, url2, body2}
      assert String.contains?(url2, "/i/v0/e/")
      assert body2["event"] == "$set"
      assert_receive {:request, url3, body3}
      assert String.contains?(url3, "/capture")
      assert body3["event"] == "app.install"
    end

    test "calls track_install/4, identify, and track with default opts" do
      prev = Application.get_env(:peek_app_sdk, :posthog_key)
      Application.put_env(:peek_app_sdk, :posthog_key, "ph_test_key")
      on_exit(fn -> Application.put_env(:peek_app_sdk, :posthog_key, prev) end)

      Tesla.Adapter.Finch
      |> Mimic.stub(:call, fn env, _opts ->
        send(self(), {:request, env.url, Jason.decode!(env.body)})

        if String.contains?(env.url, "ahem.peeklabs.com/events/") do
          {:ok, %Tesla.Env{status: 202}}
        else
          {:ok, %Tesla.Env{status: 200}}
        end
      end)

      partner = %{external_refid: "p-2", name: "Test Partner", is_test: true, platform: "peek"}

      assert {:ok, _} = PeekAppSDK.Metrics.track_install(partner)

      assert_receive {:request, url1, _}
      assert String.contains?(url1, "ahem.peeklabs.com/events/")
      assert_receive {:request, url2, body2}
      assert String.contains?(url2, "/i/v0/e/")
      assert body2["event"] == "$set"
      assert_receive {:request, url3, body3}
      assert String.contains?(url3, "/capture")
      assert body3["event"] == "app.install"
    end
  end

  describe "track_uninstall/2 with partner map" do
    test "calls track_uninstall/4 and track for PostHog" do
      prev = Application.get_env(:peek_app_sdk, :posthog_key)
      Application.put_env(:peek_app_sdk, :posthog_key, "ph_test_key")
      on_exit(fn -> Application.put_env(:peek_app_sdk, :posthog_key, prev) end)

      Tesla.Adapter.Finch
      |> Mimic.stub(:call, fn env, _opts ->
        send(self(), {:request, env.url, Jason.decode!(env.body)})

        if String.contains?(env.url, "ahem.peeklabs.com/events/") do
          {:ok, %Tesla.Env{status: 202}}
        else
          {:ok, %Tesla.Env{status: 200}}
        end
      end)

      partner = %{external_refid: "p-3", name: "Uninstall Partner", is_test: false, platform: "peek"}

      assert {:ok, _} = PeekAppSDK.Metrics.track_uninstall(partner, [])

      assert_receive {:request, url1, _}
      assert String.contains?(url1, "ahem.peeklabs.com/events/")
      assert_receive {:request, url2, body2}
      assert String.contains?(url2, "/capture")
      assert body2["event"] == "app.uninstall"
    end

    test "calls track_uninstall/4 and track with default opts" do
      prev = Application.get_env(:peek_app_sdk, :posthog_key)
      Application.put_env(:peek_app_sdk, :posthog_key, "ph_test_key")
      on_exit(fn -> Application.put_env(:peek_app_sdk, :posthog_key, prev) end)

      Tesla.Adapter.Finch
      |> Mimic.stub(:call, fn env, _opts ->
        send(self(), {:request, env.url, Jason.decode!(env.body)})

        if String.contains?(env.url, "ahem.peeklabs.com/events/") do
          {:ok, %Tesla.Env{status: 202}}
        else
          {:ok, %Tesla.Env{status: 200}}
        end
      end)

      partner = %{external_refid: "p-4", name: "Test Uninstall", is_test: true, platform: "peek"}

      assert {:ok, _} = PeekAppSDK.Metrics.track_uninstall(partner)

      assert_receive {:request, url1, _}
      assert String.contains?(url1, "ahem.peeklabs.com/events/")
      assert_receive {:request, url2, body2}
      assert String.contains?(url2, "/capture")
      assert body2["event"] == "app.uninstall"
    end
  end
end
