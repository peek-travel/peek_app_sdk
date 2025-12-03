defmodule PeekAppSDK.Metrics.PostHogTest do
  use ExUnit.Case, async: false

  alias PeekAppSDK.Metrics.PostHog

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

      partner = %{name: "Partner Name", external_refid: "1234", is_test: true}
      event_id = "app.install"

      assert {:ok, _} = PostHog.track(partner, event_id, %{foo: "bar"})

      assert_receive {:request, url, body}
      assert String.contains?(url, "/capture")
      assert body["event"] == event_id
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

      partner = %{name: "Partner Name", external_refid: "1234", is_test: false}
      event_id = "test.event"

      assert {:ok, _} = PostHog.track(partner, event_id, %{foo: "bar"})

      assert_receive {:request, url, body}
      assert String.contains?(url, "/capture")
      assert body["event"] == event_id

      refute_receive {:request, _, _}
    end
  end
end
