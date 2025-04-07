defmodule PeekAppSDK.ConfigTest do
  use ExUnit.Case, async: true

  alias PeekAppSDK.Config

  describe "get_config/1" do
    test "returns the default configuration when no identifier is provided" do
      default_config = Config.get_config()
      assert is_map(default_config)
      assert Map.has_key?(default_config, :peek_app_secret)
      assert Map.has_key?(default_config, :peek_app_id)
      assert Map.has_key?(default_config, :peek_api_url)
      assert default_config.peek_app_secret == "test_secret"
      assert default_config.peek_app_id == "test_app_id"
    end

    test "returns the configuration for a specific atom identifier" do
      # The :semnox config is set in config/test.exs
      config = Config.get_config(:semnox)
      assert is_map(config)
      assert Map.has_key?(config, :peek_app_secret)
      assert Map.has_key?(config, :peek_app_id)
      assert config.peek_app_secret == "semnox_test_secret"
      assert config.peek_app_id == "semnox_test_app_id"
    end

    test "returns the default configuration for non-existent atom identifier" do
      config = Config.get_config(:non_existent)
      assert is_map(config)
      assert Map.has_key?(config, :peek_app_secret)
      assert Map.has_key?(config, :peek_app_id)
      assert config.peek_app_secret == "test_secret"
      assert config.peek_app_id == "test_app_id"
    end
  end
end
