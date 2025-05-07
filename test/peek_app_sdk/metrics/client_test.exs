defmodule PeekAppSDK.Metrics.ClientTest do
  use ExUnit.Case, async: true
  import Mox

  alias PeekAppSDK.Metrics.Client

  setup :verify_on_exit!

  describe "track/2" do
    test "sends payload directly without validation or transformation" do
      event_id = "app.install"

      payload = %{
        anonymousId: "partner-123",
        level: "info",
        usageDisplay: "New App Installs",
        usageDetails: "Partner Name",
        postMessage: "Partner Name installed",
        customFields: %{
          "partnerId" => "partner-123",
          "partnerName" => "Partner Name"
        }
      }

      expect(PeekAppSDK.MockTeslaClient, :call, fn env, _opts ->
        assert env.method == :post

        sent_payload = Jason.decode!(env.body)
        # The eventId should be added to the payload
        assert sent_payload["eventId"] == event_id

        # All other fields should be passed through unchanged
        assert sent_payload["anonymousId"] == "partner-123"
        assert sent_payload["level"] == "info"
        assert sent_payload["usageDisplay"] == "New App Installs"
        assert sent_payload["usageDetails"] == "Partner Name"
        assert sent_payload["postMessage"] == "Partner Name installed"
        assert sent_payload["customFields"]["partnerId"] == "partner-123"
        assert sent_payload["customFields"]["partnerName"] == "Partner Name"

        {:ok, %Tesla.Env{status: 202}}
      end)

      assert {:ok, _} = Client.track(event_id, payload)
    end

    test "handles arbitrary fields in the payload" do
      event_id = "custom.event"

      payload = %{
        anonymousId: "user-123",
        someCustomField: "custom value",
        nestedData: %{
          key1: "value1",
          key2: "value2"
        },
        arrayData: [1, 2, 3]
      }

      expect(PeekAppSDK.MockTeslaClient, :call, fn env, _opts ->
        assert env.method == :post

        sent_payload = Jason.decode!(env.body)
        assert sent_payload["eventId"] == event_id
        assert sent_payload["anonymousId"] == "user-123"
        assert sent_payload["someCustomField"] == "custom value"
        assert sent_payload["nestedData"]["key1"] == "value1"
        assert sent_payload["nestedData"]["key2"] == "value2"
        assert sent_payload["arrayData"] == [1, 2, 3]

        {:ok, %Tesla.Env{status: 202}}
      end)

      assert {:ok, _} = Client.track(event_id, payload)
    end
  end

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
end
