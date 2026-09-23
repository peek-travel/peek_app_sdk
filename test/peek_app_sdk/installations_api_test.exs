defmodule PeekAppSDK.InstallationsApiTest do
  use ExUnit.Case, async: false

  alias PeekAppSDK.InstallationsApi

  describe "update_configuration_status/4" do
    test "raises error when deprecated peek_api_url is configured" do
      original_value = Application.get_env(:peek_app_sdk, :peek_api_url)

      Application.put_env(
        :peek_app_sdk,
        :peek_api_url,
        "https://apps.peekapis.com/backoffice-gql"
      )

      try do
        assert_raise RuntimeError, ~r/Configuration error: peek_api_url is deprecated/, fn ->
          InstallationsApi.update_configuration_status("install_id", "configured")
        end
      after
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

        assert env.url ==
                 "https://apps.example.peekapis.com/installations-api/test_app_id/configuration_status/#{install_id}"

        body = Jason.decode!(env.body)
        assert body["status"] == status
        assert body["notes"] == notes

        assert Enum.any?(env.headers, fn {k, v} ->
                 k == "X-Peek-Auth" && String.starts_with?(v, "Bearer ")
               end)

        {:ok, %Tesla.Env{status: 200}}
      end)

      assert :ok = InstallationsApi.update_configuration_status(install_id, status, notes)
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

      assert :ok = InstallationsApi.update_configuration_status(install_id, status)
    end

    test "handles error response from configuration status API" do
      install_id = "test_install_789"
      status = "configured"

      Tesla.Adapter.Finch
      |> Mimic.stub(:call, fn _env, _opts ->
        {:ok, %Tesla.Env{status: 404, body: %{error: "Installation not found"}}}
      end)

      assert {:error, {404, %{error: "Installation not found"}}} =
               InstallationsApi.update_configuration_status(install_id, status)
    end

    test "uses custom config_id when provided" do
      install_id = "test_install_custom"
      status = "configured"
      config_id = :project_name

      Tesla.Adapter.Finch
      |> Mimic.stub(:call, fn env, _opts ->
        assert String.contains?(env.url, "project_name_app_id")
        {:ok, %Tesla.Env{status: 200}}
      end)

      assert :ok = InstallationsApi.update_configuration_status(install_id, status, nil, config_id)
    end
  end

  describe "customize_installation/3" do
    test "successfully syncs customizations and returns the platform body" do
      install_id = "test_install_123"
      payload = %{"foo" => "bar"}
      response_body = %{"foo" => "bar", "synced" => true}

      Tesla.Adapter.Finch
      |> Mimic.stub(:call, fn env, _opts ->
        assert env.method == :post

        assert env.url ==
                 "https://apps.example.peekapis.com/installations-api/test_app_id/customizations"

        assert Jason.decode!(env.body) == payload

        assert Enum.any?(env.headers, fn {k, v} ->
                 k == "X-Peek-Auth" && String.starts_with?(v, "Bearer ")
               end)

        {:ok, %Tesla.Env{status: 200, body: response_body}}
      end)

      assert {:ok, ^response_body} =
               InstallationsApi.customize_installation(install_id, payload)
    end

    test "returns the platform's error body unchanged on non-2xx status" do
      install_id = "test_install_456"
      payload = %{"foo" => "bar"}
      error_body = %{"error" => "Unsupported platform: acme"}

      Tesla.Adapter.Finch
      |> Mimic.stub(:call, fn _env, _opts ->
        {:ok, %Tesla.Env{status: 400, body: error_body}}
      end)

      assert {:error, {400, ^error_body}} =
               InstallationsApi.customize_installation(install_id, payload)
    end

    test "uses custom config_id when provided" do
      install_id = "test_install_custom"
      payload = %{"foo" => "bar"}
      config_id = :project_name

      Tesla.Adapter.Finch
      |> Mimic.stub(:call, fn env, _opts ->
        assert String.contains?(env.url, "project_name_app_id")

        assert Enum.any?(env.headers, fn {k, v} ->
                 k == "pk-api-key" && v == "project_name_api_key"
               end)

        {:ok, %Tesla.Env{status: 200, body: %{}}}
      end)

      assert {:ok, %{}} =
               InstallationsApi.customize_installation(install_id, payload, config_id)
    end
  end
end
