defmodule PeekAppSDKTest do
  use ExUnit.Case, async: false

  describe "query_peek_pro/4" do
    test "delegates to Client.query_peek_pro/4 with default config" do
      install_id = "test_install_id"
      query = "query Test { test }"
      variables = %{foo: "bar"}

      # Mock the HTTP response for this test
      Tesla.Adapter.Finch
      |> Mimic.stub(:call, fn _env, _opts ->
        {:ok, %Tesla.Env{status: 200, body: %{data: %{test: "success"}}}}
      end)

      assert {:ok, %{test: "success"}} = PeekAppSDK.query_peek_pro(install_id, query, variables)
    end

    test "delegates to Client.query_peek_pro/4 with atom config_id" do
      install_id = "test_install_id"
      query = "query Test { test }"
      variables = %{foo: "bar"}

      # Mock the HTTP response for this test
      Tesla.Adapter.Finch
      |> Mimic.stub(:call, fn _env, _opts ->
        {:ok, %Tesla.Env{status: 200, body: %{data: %{test: "success"}}}}
      end)

      assert {:ok, %{test: "success"}} =
               PeekAppSDK.query_peek_pro(install_id, query, variables, :project_name)
    end
  end

  describe "update_configuration_status/4" do
    test "delegates to InstallationsApi.update_configuration_status/4" do
      Tesla.Adapter.Finch
      |> Mimic.stub(:call, fn _env, _opts ->
        {:ok, %Tesla.Env{status: 200}}
      end)

      assert :ok = PeekAppSDK.update_configuration_status("install_id", "configured")
    end
  end

  describe "customize_installation/3" do
    test "delegates to InstallationsApi.customize_installation/3" do
      response_body = %{"synced" => true}

      Tesla.Adapter.Finch
      |> Mimic.stub(:call, fn _env, _opts ->
        {:ok, %Tesla.Env{status: 200, body: response_body}}
      end)

      assert {:ok, ^response_body} =
               PeekAppSDK.customize_installation("install_id", %{"foo" => "bar"})
    end
  end

  describe "get_customizations/2" do
    test "delegates to InstallationsApi.get_customizations/2" do
      response_body = %{customizations: %{"some_slug@v1" => %{"foo" => "bar"}}}

      Tesla.Adapter.Finch
      |> Mimic.stub(:call, fn _env, _opts ->
        {:ok, %Tesla.Env{status: 200, body: response_body}}
      end)

      assert {:ok, ^response_body} = PeekAppSDK.get_customizations("install_id")
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
end
