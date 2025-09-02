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
end
