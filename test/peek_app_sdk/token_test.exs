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
end
