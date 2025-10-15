defmodule PeekAppSDK.ConfigTest do
  use ExUnit.Case, async: true

  alias PeekAppSDK.Config

  describe "get_config/1" do
    test "returns the default configuration when no identifier is provided" do
      default_config = Config.get_config()
      assert is_map(default_config)
      assert Map.has_key?(default_config, :peek_app_secret)
      assert Map.has_key?(default_config, :peek_app_id)
      assert Map.has_key?(default_config, :peek_api_base_url)
      assert Map.has_key?(default_config, :client_secret_token)
      assert default_config.peek_app_secret == "test_secret"
      assert default_config.peek_app_id == "test_app_id"
      assert default_config.client_secret_token == "test_client_secret"
    end

    test "raises error when deprecated peek_api_url is configured and check_deprecated_config! is called" do
      # Temporarily set the deprecated config
      original_value = Application.get_env(:peek_app_sdk, :peek_api_url)

      Application.put_env(
        :peek_app_sdk,
        :peek_api_url,
        "https://apps.peekapis.com/backoffice-gql"
      )

      try do
        assert_raise RuntimeError, ~r/Configuration error: peek_api_url is deprecated/, fn ->
          Config.check_deprecated_config!()
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

    test "returns the configuration for project_name from apps config" do
      config = Config.get_config(:project_name)
      assert is_map(config)
      assert Map.has_key?(config, :peek_app_secret)
      assert Map.has_key?(config, :peek_app_id)
      assert Map.has_key?(config, :client_secret_token)
      assert config.peek_app_secret == "project_name_app_secret"
      assert config.peek_app_id == "project_name_app_id"
      assert config.peek_api_key == "project_name_api_key"
      assert config.client_secret_token == "project_name_client_secret"
    end

    test "returns the configuration for other_app from apps config" do
      config = Config.get_config(:other_app)
      assert is_map(config)
      assert Map.has_key?(config, :peek_app_secret)
      assert Map.has_key?(config, :peek_app_id)
      assert Map.has_key?(config, :client_secret_token)
      assert config.peek_app_secret == "other_app_secret"
      assert config.peek_app_id == "other_app_id"
      assert config.peek_api_key == nil
      assert config.client_secret_token == nil
    end

    test "returns the configuration for client_only_app from apps config" do
      config = Config.get_config(:client_only_app)
      assert is_map(config)
      assert Map.has_key?(config, :peek_app_secret)
      assert Map.has_key?(config, :peek_app_id)
      assert Map.has_key?(config, :client_secret_token)
      assert config.peek_app_secret == "client_only_app_secret"
      assert config.peek_app_id == "client_only_app_id"
      assert config.client_secret_token == "client_only_secret"
    end

    test "returns the default configuration for non-existent atom identifier" do
      config = Config.get_config(:non_existent)
      assert is_map(config)
      assert Map.has_key?(config, :peek_app_secret)
      assert Map.has_key?(config, :peek_app_id)
      assert Map.has_key?(config, :client_secret_token)
      assert config.peek_app_secret == "test_secret"
      assert config.peek_app_id == "test_app_id"
      assert config.client_secret_token == "test_client_secret"
    end
  end
end
