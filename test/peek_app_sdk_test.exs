defmodule PeekAppSDKTest do
  use ExUnit.Case, async: true
  import Mox

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
               PeekAppSDK.query_peek_pro(install_id, query, variables, :semnox)
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

    test "get_config/1 returns configuration for semnox from apps config" do
      config = PeekAppSDK.get_config(:semnox)
      assert is_map(config)
      assert Map.has_key?(config, :peek_app_secret)
      assert Map.has_key?(config, :peek_app_id)
      assert config.peek_app_secret == "semnox_app_secret"
      assert config.peek_app_id == "semnox_app_id"
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
end
