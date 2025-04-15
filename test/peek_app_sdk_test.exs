defmodule PeekAppSDKTest do
  use ExUnit.Case, async: true
  import Mox

  alias PeekAppSDK.Health.Models.EventPayload

  setup :verify_on_exit!

  describe "query_peek_pro/4" do
    test "delegates to Client.query_peek_pro/4 with default config" do
      install_id = "test_install_id"
      query = "query Test { test }"
      variables = %{foo: "bar"}
      response_data = %{test: "success"}

      expect(PeekAppSDK.MockTeslaClient, :call, fn _env, _opts ->
        {:ok, %Tesla.Env{status: 200, body: %{data: response_data}}}
      end)

      assert {:ok, ^response_data} = PeekAppSDK.query_peek_pro(install_id, query, variables)
    end

    test "delegates to Client.query_peek_pro/4 with atom config_id" do
      install_id = "test_install_id"
      query = "query Test { test }"
      variables = %{foo: "bar"}
      response_data = %{test: "success"}

      expect(PeekAppSDK.MockTeslaClient, :call, fn _env, _opts ->
        {:ok, %Tesla.Env{status: 200, body: %{data: response_data}}}
      end)

      assert {:ok, ^response_data} =
               PeekAppSDK.query_peek_pro(install_id, query, variables, :project_name)
    end
  end

  describe "config management" do
    test "get_config/1 returns configuration for default" do
      config = PeekAppSDK.get_config()
      assert is_map(config)
      assert Map.has_key?(config, :peek_app_secret)
      assert Map.has_key?(config, :peek_app_id)
      assert config.peek_app_secret == "test_secret"
      assert config.peek_app_id == "test_app_id"
    end

    test "get_config/1 returns configuration for project_name from apps config" do
      config = PeekAppSDK.get_config(:project_name)
      assert is_map(config)
      assert Map.has_key?(config, :peek_app_secret)
      assert Map.has_key?(config, :peek_app_id)
      assert config.peek_app_secret == "project_name_app_secret"
      assert config.peek_app_id == "project_name_app_id"
    end

    test "get_config/1 returns configuration for other app from apps config" do
      config = PeekAppSDK.get_config(:other_app)
      assert is_map(config)
      assert Map.has_key?(config, :peek_app_secret)
      assert Map.has_key?(config, :peek_app_id)
      assert config.peek_app_secret == "other_app_secret"
      assert config.peek_app_id == "other_app_id"
    end
  end

  describe "track_event/3" do
    test "delegates to Health.track_event/3 with default config" do
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

      assert {:ok, result} = PeekAppSDK.track_event(monitored_app_id, payload)
      assert result.success == true
      assert result.message == "Event tracked successfully"
      assert result.event_id == "1625097600000_abc123"
    end

    test "delegates to Health.track_event/3 with atom config_id" do
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

      assert {:ok, _result} = PeekAppSDK.track_event(monitored_app_id, payload, :project_name)
    end
  end

  describe "track_info_event/5" do
    test "delegates to Health.track_info_event/5" do
      monitored_app_id = "test-app-123"
      event_id = "app.install"
      anonymous_id = "anon-123456"
      opts = %{user_id: "user-789012"}

      response_data = %{
        "success" => true,
        "message" => "Event tracked successfully",
        "eventId" => "1625097600000_abc123"
      }

      expect(PeekAppSDK.MockTeslaClient, :call, fn _env, _opts ->
        {:ok, %Tesla.Env{status: 200, body: response_data}}
      end)

      assert {:ok, _result} =
               PeekAppSDK.track_info_event(monitored_app_id, event_id, anonymous_id, opts)
    end
  end

  describe "track_error_event/5" do
    test "delegates to Health.track_error_event/5" do
      monitored_app_id = "test-app-123"
      event_id = "app.error"
      anonymous_id = "anon-123456"
      opts = %{user_id: "user-789012"}

      response_data = %{
        "success" => true,
        "message" => "Event tracked successfully",
        "eventId" => "1625097600000_abc123"
      }

      expect(PeekAppSDK.MockTeslaClient, :call, fn _env, _opts ->
        {:ok, %Tesla.Env{status: 200, body: response_data}}
      end)

      assert {:ok, _result} =
               PeekAppSDK.track_error_event(monitored_app_id, event_id, anonymous_id, opts)
    end
  end
end
