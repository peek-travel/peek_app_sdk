defmodule PeekAppSDK.TokenTest do
  use ExUnit.Case, async: true

  alias PeekAppSDK.Token

  describe "verify_peek_auth/2" do
    test "successfully verifies a valid token with default config" do
      install_id = "test_install_id"
      token = Token.new_for_app_installation!(install_id)

      assert {:ok, ^install_id, _claims} = Token.verify_peek_auth(token)
    end

    test "successfully verifies a valid token with atom config_id" do
      install_id = "test_install_id"
      token = Token.new_for_app_installation!(install_id, nil, :project_name)

      assert {:ok, ^install_id, _claims} = Token.verify_peek_auth(token, :project_name)
    end

    test "returns error for invalid token" do
      assert {:error, :unauthorized} = Token.verify_peek_auth("invalid_token")
    end

    test "returns error for expired token" do
      install_id = "test_install_id"
      config = PeekAppSDK.Config.get_config()
      shared_secret_key = config.peek_app_secret
      signer = Joken.Signer.create("HS256", shared_secret_key)

      params = %{
        "iss" => "peek_app_sdk",
        "sub" => install_id,
        "exp" => DateTime.utc_now() |> DateTime.add(-60) |> DateTime.to_unix()
      }

      {:ok, token, _claims} = Token.generate_and_sign(params, signer)

      assert {:error, :unauthorized} = Token.verify_peek_auth(token)
    end

    test "returns error when verifying with wrong config" do
      # The default config and project_name config have different secrets
      install_id = "test_install_id"
      token = Token.new_for_app_installation!(install_id)

      # Verify with wrong config should fail
      assert {:error, :unauthorized} = Token.verify_peek_auth(token, :project_name)
    end
  end

  describe "new_for_app_installation!/2" do
    test "generates a valid token with default config" do
      install_id = "test_install_id"
      token = Token.new_for_app_installation!(install_id)

      assert is_binary(token)
      assert {:ok, ^install_id, claims} = Token.verify_peek_auth(token)
      assert claims["iss"] == "peek_app_sdk"
      assert claims["sub"] == install_id
      assert claims["exp"]
      assert claims["current_user_email"] == nil
      assert claims["current_user_id"] == nil
      assert claims["current_user_is_peek_admin"] == nil
      assert claims["current_user_name"] == "hook"
      assert claims["current_user_primary_role"] == nil
    end

    test "generates a valid token with atom config_id" do
      install_id = "test_install_id"
      token = Token.new_for_app_installation!(install_id, nil, :project_name)

      assert is_binary(token)
      assert {:ok, ^install_id, _claims} = Token.verify_peek_auth(token, :project_name)
    end

    test "token expires in 60 seconds" do
      install_id = "test_install_id"
      token = Token.new_for_app_installation!(install_id)

      config = PeekAppSDK.Config.get_config()
      shared_secret_key = config.peek_app_secret
      signer = Joken.Signer.create("HS256", shared_secret_key)

      {:ok, claims} = Token.verify_and_validate(token, signer)
      now = DateTime.utc_now() |> DateTime.to_unix()

      assert_in_delta claims["exp"], now + 60, 2
    end
  end

  describe "verify_client_request/2" do
    test "returns error for invalid token" do
      assert {:error, :unauthorized} = Token.verify_client_request("invalid_token")
    end

    test "returns error when client_secret_token is not configured" do
      install_id = "test_install_id"
      # Use other_app which doesn't have client_secret_token configured
      token = Token.new_for_app_installation!(install_id, nil, :other_app)

      assert {:error, :unauthorized} = Token.verify_client_request(token, :other_app)
    end

    test "returns error for expired token" do
      install_id = "test_install_id"
      config = PeekAppSDK.Config.get_config()
      client_secret_key = config.client_secret_token
      signer = Joken.Signer.create("HS256", client_secret_key)

      params = %{
        "iss" => "peek_app_sdk",
        "sub" => install_id,
        "exp" => DateTime.utc_now() |> DateTime.add(-60) |> DateTime.to_unix()
      }

      {:ok, token, _claims} = Token.generate_and_sign(params, signer)

      assert {:error, :unauthorized} = Token.verify_client_request(token)
    end

    test "returns error for token signed with wrong secret" do
      install_id = "test_install_id"
      # Create token with peek_app_secret
      token = Token.new_for_app_installation!(install_id)

      # Try to verify with client_secret_token
      assert {:error, :unauthorized} = Token.verify_client_request(token)
    end

    test "returns error for malformed token in verify_peek_auth" do
      # Test the default case in verify_peek_auth
      assert {:error, :unauthorized} = Token.verify_peek_auth("malformed.token.here")
    end

    test "returns error for malformed token in verify_client_request" do
      # Test the default case in verify_client_request
      assert {:error, :unauthorized} = Token.verify_client_request("malformed.token.here")
    end

    test "returns error for token without sub claim in verify_peek_auth" do
      # Create a token without the "sub" claim to trigger the default case
      config = PeekAppSDK.Config.get_config()
      shared_secret_key = config.peek_app_secret
      signer = Joken.Signer.create("HS256", shared_secret_key)

      params = %{
        "iss" => "peek_app_sdk",
        "exp" => DateTime.utc_now() |> DateTime.add(60) |> DateTime.to_unix()
        # Missing "sub" claim
      }

      {:ok, token, _claims} = Token.generate_and_sign(params, signer)
      assert {:error, :unauthorized} = Token.verify_peek_auth(token)
    end

    test "returns error for token without sub claim in verify_client_request" do
      # Create a token without the "sub" claim to trigger the default case
      config = PeekAppSDK.Config.get_config()
      client_secret_key = config.client_secret_token
      signer = Joken.Signer.create("HS256", client_secret_key)

      params = %{
        "iss" => "peek_app_sdk",
        "exp" => DateTime.utc_now() |> DateTime.add(60) |> DateTime.to_unix()
        # Missing "sub" claim
      }

      {:ok, token, _claims} = Token.generate_and_sign(params, signer)
      assert {:error, :unauthorized} = Token.verify_client_request(token)
    end
  end

  describe "new_for_app_installation_client/2" do
    test "generates a valid client token with default config" do
      install_id = "test_install_id"
      token = Token.new_for_app_installation_client(install_id)

      assert is_binary(token)
      assert {:ok, ^install_id, claims} = Token.verify_client_request(token)
      assert claims["iss"] == "app_registry_client"
      assert claims["sub"] == install_id
      assert claims["exp"]
      assert claims["current_user_email"] == nil
      assert claims["current_user_id"] == nil
      assert claims["current_user_is_peek_admin"] == nil
      assert claims["current_user_name"] == nil
      assert claims["current_user_primary_role"] == nil
    end

    test "generates a valid client token with atom config_id" do
      install_id = "test_install_id"
      token = Token.new_for_app_installation_client(install_id, :project_name)

      assert is_binary(token)
      assert {:ok, ^install_id, _claims} = Token.verify_client_request(token, :project_name)
    end
  end
end
