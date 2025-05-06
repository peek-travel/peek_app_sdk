defmodule PeekAppSDK.Metrics.ClientTest do
  use ExUnit.Case, async: true
  import Mox

  alias PeekAppSDK.Metrics.Client

  setup :verify_on_exit!

  describe "track_install/3" do
    test "sends correct payload for regular installation" do
      external_refid = "partner-123"
      name = "Partner Name"
      is_test = false

      expect(PeekAppSDK.MockTeslaClient, :call, fn env, _opts ->
        assert env.method == :post
        assert String.contains?(env.url, "ahem.peeklabs.com/events/")

        payload = Jason.decode!(env.body)
        assert payload["eventId"] == "app.install"
        assert payload["level"] == "info"
        assert payload["anonymousId"] == external_refid
        assert payload["usageDisplay"] == "New App Installs"
        assert payload["usageDetails"] == name
        assert payload["postMessage"] == "#{name} installed"

        assert payload["customFields"] == %{
                 "partnerName" => name,
                 "partnerExternalRefid" => external_refid,
                 "partnerIsTest" => is_test
               }

        {:ok, %Tesla.Env{status: 202}}
      end)

      assert {:ok, _} = Client.track_install(external_refid, name, is_test)
    end

    test "sends correct payload for test installation" do
      external_refid = "partner-test-123"
      name = "Test Partner"
      is_test = true

      expect(PeekAppSDK.MockTeslaClient, :call, fn env, _opts ->
        assert env.method == :post

        payload = Jason.decode!(env.body)
        assert payload["eventId"] == "app.install"
        assert payload["usageDisplay"] == "New TEST App Installs"
        assert payload["customFields"]["partnerIsTest"] == true

        {:ok, %Tesla.Env{status: 202}}
      end)

      assert {:ok, _} = Client.track_install(external_refid, name, is_test)
    end
  end

  describe "track_uninstall/3" do
    test "sends correct payload for regular uninstallation" do
      external_refid = "partner-123"
      name = "Partner Name"
      is_test = false

      expect(PeekAppSDK.MockTeslaClient, :call, fn env, _opts ->
        assert env.method == :post

        payload = Jason.decode!(env.body)
        assert payload["eventId"] == "app.uninstall"
        assert payload["level"] == "info"
        assert payload["anonymousId"] == external_refid
        assert payload["usageDisplay"] == "New App Uninstalls"
        assert payload["usageDetails"] == name
        assert payload["postMessage"] == "#{name} uninstalled"

        assert payload["customFields"] == %{
                 "partnerName" => name,
                 "partnerExternalRefid" => external_refid,
                 "partnerIsTest" => is_test
               }

        {:ok, %Tesla.Env{status: 202}}
      end)

      assert {:ok, _} = Client.track_uninstall(external_refid, name, is_test)
    end

    test "sends correct payload for test uninstallation" do
      external_refid = "partner-test-123"
      name = "Test Partner"
      is_test = true

      expect(PeekAppSDK.MockTeslaClient, :call, fn env, _opts ->
        assert env.method == :post

        payload = Jason.decode!(env.body)
        assert payload["eventId"] == "app.uninstall"
        assert payload["usageDisplay"] == "New TEST App Uninstalls"
        assert payload["customFields"]["partnerIsTest"] == true

        {:ok, %Tesla.Env{status: 202}}
      end)

      assert {:ok, _} = Client.track_uninstall(external_refid, name, is_test)
    end
  end

  describe "track_event/6" do
    test "sends correct payload for custom event" do
      external_refid = "partner-123"
      name = "Partner Name"
      is_test = false
      event_id = "custom.event"
      level = "info"

      expect(PeekAppSDK.MockTeslaClient, :call, fn env, _opts ->
        assert env.method == :post

        payload = Jason.decode!(env.body)
        assert payload["eventId"] == event_id
        assert payload["level"] == level
        assert payload["anonymousId"] == external_refid

        assert payload["customFields"] == %{
                 "partnerName" => name,
                 "partnerExternalRefid" => external_refid,
                 "partnerIsTest" => is_test
               }

        {:ok, %Tesla.Env{status: 202}}
      end)

      assert {:ok, _} = Client.track_event(external_refid, name, is_test, event_id)
    end

    test "uses custom anonymous_id when provided" do
      external_refid = "partner-123"
      name = "Partner Name"
      is_test = false
      event_id = "custom.event"
      level = "debug"
      anonymous_id = "custom-id-123"

      expect(PeekAppSDK.MockTeslaClient, :call, fn env, _opts ->
        assert env.method == :post

        payload = Jason.decode!(env.body)
        assert payload["eventId"] == event_id
        assert payload["level"] == level
        # Should use the custom ID
        assert payload["anonymousId"] == anonymous_id

        {:ok, %Tesla.Env{status: 202}}
      end)

      assert {:ok, _} =
               Client.track_event(external_refid, name, is_test, event_id, level, anonymous_id)
    end

    test "uses custom level when provided" do
      external_refid = "partner-123"
      name = "Partner Name"
      is_test = false
      event_id = "custom.event"
      level = "error"

      expect(PeekAppSDK.MockTeslaClient, :call, fn env, _opts ->
        assert env.method == :post

        payload = Jason.decode!(env.body)
        assert payload["level"] == level

        {:ok, %Tesla.Env{status: 202}}
      end)

      assert {:ok, _} = Client.track_event(external_refid, name, is_test, event_id, level)
    end
  end
end
