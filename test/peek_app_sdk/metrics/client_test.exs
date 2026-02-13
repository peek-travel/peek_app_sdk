defmodule PeekAppSDK.Metrics.ClientTest do
  use ExUnit.Case, async: false

  alias PeekAppSDK.Metrics.Client

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

      Tesla.Adapter.Finch
      |> Mimic.stub(:call, fn env, _opts ->
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

      Tesla.Adapter.Finch
      |> Mimic.stub(:call, fn env, _opts ->
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

      Tesla.Adapter.Finch
      |> Mimic.stub(:call, fn env, _opts ->
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

      assert {:ok, _} = Client.track_install(external_refid, name, is_test, post_message: true)
    end

    test "sends correct payload for test installation" do
      external_refid = "partner-test-123"
      name = "Test Partner"
      is_test = true

      Tesla.Adapter.Finch
      |> Mimic.stub(:call, fn env, _opts ->
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

      Tesla.Adapter.Finch
      |> Mimic.stub(:call, fn env, _opts ->
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

      assert {:ok, _} =
               Client.track_uninstall(external_refid, name, is_test, post_message: true)
    end

    test "sends correct payload for test uninstallation" do
      external_refid = "partner-test-123"
      name = "Test Partner"
      is_test = true

      Tesla.Adapter.Finch
      |> Mimic.stub(:call, fn env, _opts ->
        assert env.method == :post

        payload = Jason.decode!(env.body)
        assert payload["eventId"] == "app.uninstall"
        assert payload["usageDisplay"] == "New TEST App Uninstalls"
        assert payload["customFields"]["partnerIsTest"] == true

        {:ok, %Tesla.Env{status: 202}}
      end)

      assert {:ok, _} = Client.track_uninstall(external_refid, name, is_test)
    end

    test "handles error response from metrics API" do
      external_refid = "partner-123"
      name = "Partner Name"
      is_test = false

      Tesla.Adapter.Finch
      |> Mimic.stub(:call, fn env, _opts ->
        assert env.method == :post
        {:ok, %Tesla.Env{status: 500, body: %{error: "Internal server error"}}}
      end)

      assert {:error, {500, %{error: "Internal server error"}}} =
               Client.track_install(external_refid, name, is_test)
    end
  end

  describe "update_configuration_status/4" do
    test "raises error when deprecated peek_api_url is configured" do
      # Temporarily set the deprecated config
      original_value = Application.get_env(:peek_app_sdk, :peek_api_url)

      Application.put_env(
        :peek_app_sdk,
        :peek_api_url,
        "https://apps.peekapis.com/backoffice-gql"
      )

      try do
        assert_raise RuntimeError, ~r/Configuration error: peek_api_url is deprecated/, fn ->
          Client.update_configuration_status("install_id", "configured")
        end
      after
        # Restore original value (should be nil in tests)
        if original_value do
          Application.put_env(:peek_app_sdk, :peek_api_url, original_value)
        else
          Application.delete_env(:peek_app_sdk, :peek_api_url)
        end
      end
    end

    test "successfully updates configuration status" do
      install_id = "test_install_123"
      status = "configured"
      notes = "Configuration completed successfully"

      Tesla.Adapter.Finch
      |> Mimic.stub(:call, fn env, _opts ->
        assert env.method == :put
        assert String.contains?(env.url, "/registry/installations/")
        assert String.contains?(env.url, install_id)
        assert String.contains?(env.url, "/configuration_status")

        body = Jason.decode!(env.body)
        assert body["status"] == status
        assert body["notes"] == notes

        {:ok, %Tesla.Env{status: 200}}
      end)

      assert :ok = Client.update_configuration_status(install_id, status, notes)
    end

    test "successfully updates configuration status without notes" do
      install_id = "test_install_456"
      status = "pending"

      Tesla.Adapter.Finch
      |> Mimic.stub(:call, fn env, _opts ->
        assert env.method == :put

        body = Jason.decode!(env.body)
        assert body["status"] == status
        assert body["notes"] == nil

        {:ok, %Tesla.Env{status: 200}}
      end)

      assert :ok = Client.update_configuration_status(install_id, status)
    end

    test "handles error response from configuration status API" do
      install_id = "test_install_789"
      status = "configured"

      Tesla.Adapter.Finch
      |> Mimic.stub(:call, fn env, _opts ->
        assert env.method == :put
        {:ok, %Tesla.Env{status: 404, body: %{error: "Installation not found"}}}
      end)

      assert {:error, {404, %{error: "Installation not found"}}} =
               Client.update_configuration_status(install_id, status)
    end

    test "uses custom config_id when provided" do
      install_id = "test_install_custom"
      status = "configured"
      config_id = :project_name

      Tesla.Adapter.Finch
      |> Mimic.stub(:call, fn env, _opts ->
        assert env.method == :put
        # Should use project_name's app_id from config
        assert String.contains?(env.url, "project_name_app_id")

        {:ok, %Tesla.Env{status: 200}}
      end)

      assert :ok = Client.update_configuration_status(install_id, status, nil, config_id)
    end

    test "uses config without peek_api_key" do
      install_id = "test_install_no_key"
      status = "configured"
      config_id = :other_app

      Tesla.Adapter.Finch
      |> Mimic.stub(:call, fn env, _opts ->
        assert env.method == :put
        # Should use other_app's app_id from config
        assert String.contains?(env.url, "other_app_id")
        # Should only have X-Peek-Auth header, not pk-api-key
        headers = Map.new(env.headers)
        assert Map.has_key?(headers, "X-Peek-Auth")
        refute Map.has_key?(headers, "pk-api-key")

        {:ok, %Tesla.Env{status: 200}}
      end)

      assert :ok = Client.update_configuration_status(install_id, status, nil, config_id)
    end
  end
end
