defmodule PeekAppSDK.ClientTest do
  use ExUnit.Case, async: false
  import ExUnit.CaptureLog

  alias PeekAppSDK.Client

  describe "query_peek_pro/4" do
    test "successfully queries Peek Pro with default config" do
      install_id = "test_install_id"
      query = "query TestOperationName { test }"
      variables = %{"foo" => "bar"}
      response_data = %{test: "success"}

      Tesla.Adapter.Finch
      |> Mimic.stub(:call, fn env, _opts ->
        assert env.method == :post

        assert env.url ==
                 "https://apps.peekapis.com/backoffice-gql/test_app_id/test_operation_name"

        assert Jason.decode!(env.body) == %{
                 "query" => query,
                 "variables" => variables
               }

        assert Enum.any?(env.headers, fn {k, v} ->
                 k == "X-Peek-Auth" && String.starts_with?(v, "Bearer ")
               end)

        {:ok, %Tesla.Env{status: 200, body: %{data: response_data}}}
      end)

      assert {:ok, ^response_data} = Client.query_peek_pro(install_id, query, variables)
    end

    test "successfully queries Peek Pro with atom config_id" do
      install_id = "test_install_id"
      query = "query Test { test }"
      variables = %{"foo" => "bar"}
      response_data = %{test: "success"}

      Tesla.Adapter.Finch
      |> Mimic.stub(:call, fn env, _opts ->
        assert env.method == :post

        assert env.url ==
                 "https://apps.peekapis.com/backoffice-gql/project_name_app_id/test"

        assert Jason.decode!(env.body) == %{
                 "query" => query,
                 "variables" => variables
               }

        assert Enum.any?(env.headers, fn {k, v} ->
                 k == "X-Peek-Auth" && String.starts_with?(v, "Bearer ")
               end)

        assert Enum.any?(env.headers, fn {k, v} ->
                 k == "pk-api-key" && v == "project_name_api_key"
               end)

        {:ok, %Tesla.Env{status: 200, body: %{data: response_data}}}
      end)

      assert {:ok, ^response_data} =
               Client.query_peek_pro(install_id, query, variables, :project_name)
    end

    test "token is signed with the right peek_app_secret" do
      install_id = "test_install_id"
      query = "query Test { test }"
      variables = %{"foo" => "bar"}
      response_data = %{test: "success"}

      Tesla.Adapter.Finch
      |> Mimic.stub(:call, fn env, _opts ->
        assert env.method == :post

        assert env.url ==
                 "https://apps.peekapis.com/backoffice-gql/project_name_app_id/test"

        assert Jason.decode!(env.body) == %{
                 "query" => query,
                 "variables" => variables
               }

        bearer_token =
          env.headers
          |> Enum.find(fn {k, _v} ->
            k == "X-Peek-Auth"
          end)
          |> elem(1)

        assert String.starts_with?(bearer_token, "Bearer ")
        assert String.length(bearer_token) > 10

        token = String.replace_prefix(bearer_token, "Bearer ", "")

        assert {:ok, ^install_id, _claims} =
                 PeekAppSDK.Token.verify_peek_auth(token, :project_name)

        assert PeekAppSDK.Token.verify_peek_auth(token) == {:error, :unauthorized}

        {:ok, %Tesla.Env{status: 200, body: %{data: response_data}}}
      end)

      assert {:ok, ^response_data} =
               Client.query_peek_pro(install_id, query, variables, :project_name)
    end

    test "pk-api-key only sent if peek_api_key is set" do
      install_id = "test_install_id"
      query = "query Test { test }"
      variables = %{"foo" => "bar"}
      response_data = %{test: "success"}

      Tesla.Adapter.Finch
      |> Mimic.stub(:call, fn env, _opts ->
        assert env.method == :post
        assert env.url == "https://apps.peekapis.com/backoffice-gql/other_app_id/test"

        assert Jason.decode!(env.body) == %{
                 "query" => query,
                 "variables" => variables
               }

        assert Enum.any?(env.headers, fn {k, v} ->
                 k == "X-Peek-Auth" && String.starts_with?(v, "Bearer ")
               end)

        assert Enum.filter(env.headers, fn {k, _v} ->
                 k == "pk-api-key"
               end) == []

        {:ok, %Tesla.Env{status: 200, body: %{data: response_data}}}
      end)

      assert {:ok, ^response_data} =
               Client.query_peek_pro(install_id, query, variables, :other_app)
    end

    test "handles error response" do
      install_id = "test_install_id"
      query = "query Test { test }"

      Tesla.Adapter.Finch
      |> Mimic.stub(:call, fn _env, _opts ->
        {:ok, %Tesla.Env{status: 400}}
      end)

      assert {:error, 400} = Client.query_peek_pro(install_id, query)
    end

    test "handles error response with body" do
      install_id = "test_install_id"
      query = "query Test { test }"
      error_body = %{errors: [%{message: "Something went wrong"}]}

      Tesla.Adapter.Finch
      |> Mimic.stub(:call, fn _env, _opts ->
        {:ok, %Tesla.Env{status: 400, body: error_body}}
      end)

      assert {:error, 400} = Client.query_peek_pro(install_id, query)
    end

    test "bubbles up errors from PeekPro when status is 200 but errors key is present" do
      install_id = "test_install_id"
      query = "query Test { test }"

      errors = [
        %{message: "Field 'test' is required"},
        %{message: "Invalid input provided"}
      ]

      Tesla.Adapter.Finch
      |> Mimic.stub(:call, fn _env, _opts ->
        {:ok, %Tesla.Env{status: 200, body: %{errors: errors}}}
      end)

      assert {:error, ^errors} = Client.query_peek_pro(install_id, query)
    end

    test "uses legacy peek_api_url when configured and logs warning" do
      install_id = "test_install_id"
      query = "query TestOperationName { test }"
      response_data = %{test: "success"}

      # Temporarily set the legacy config
      original_value = Application.get_env(:peek_app_sdk, :peek_api_url)

      Application.put_env(
        :peek_app_sdk,
        :peek_api_url,
        "https://legacy.peekapis.com/backoffice-gql"
      )

      try do
        # Capture log output
        log_output =
          capture_log(fn ->
            Tesla.Adapter.Finch
            |> Mimic.stub(:call, fn env, _opts ->
              assert env.method == :post
              # Should use legacy URL directly without appending /backoffice-gql
              assert env.url ==
                       "https://legacy.peekapis.com/backoffice-gql/test_app_id/test_operation_name"

              {:ok, %Tesla.Env{status: 200, body: %{data: response_data}}}
            end)

            assert {:ok, ^response_data} = Client.query_peek_pro(install_id, query)
          end)

        assert log_output =~ "DEPRECATION WARNING: peek_api_url configuration is deprecated"
      after
        # Restore original value
        if original_value do
          Application.put_env(:peek_app_sdk, :peek_api_url, original_value)
        else
          Application.delete_env(:peek_app_sdk, :peek_api_url)
        end
      end
    end
  end

  describe "operation_name/1" do
    test "extracts operation name from query" do
      query = "query TestOperation { test }"
      assert Client.operation_name(query) == "test_operation"
    end

    test "extracts operation name from mutation" do
      query = "mutation UpdateTest { update }"
      assert Client.operation_name(query) == "update_test"
    end

    test "extracts operation name from subscription" do
      query = "subscription WatchTest { watch }"
      assert Client.operation_name(query) == "watch_test"
    end

    test "raises error when no operation name is provided" do
      query = "query { test }"
      assert_raise RuntimeError, fn -> Client.operation_name(query) end
    end
  end
end
