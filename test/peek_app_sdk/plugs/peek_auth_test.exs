defmodule PeekAppSDK.Plugs.PeekAuthTest do
  use ExUnit.Case, async: true

  import Plug.Test
  import Plug.Conn

  alias PeekAppSDK.Plugs.PeekAuth
  alias PeekAppSDK.Token

  describe "allow_peek_iframe/2" do
    test "adds CSP header" do
      conn = conn(:get, "/")
      conn = PeekAuth.allow_peek_iframe(conn, %{})

      assert get_resp_header(conn, "content-security-policy") == ["frame-ancestors 'self' *"]
    end
  end

  describe "set_peek_install_id/2" do
    test "sets install ID from body params with default config" do
      install_id = "test_install_id"
      token = Token.new_for_app_installation!(install_id)
      conn = conn(:post, "/", %{"peek-auth" => token})

      conn = PeekAuth.set_peek_install_id(conn, %{})

      assert conn.assigns.peek_install_id == install_id
      assert conn.assigns.peek_install_token == token
      assert conn.assigns.peek_config_id == nil

      # Don't test session in tests since it's not properly initialized
      # and we're now handling that gracefully in the implementation
    end

    test "sets install ID from body params with atom config_id" do
      install_id = "test_install_id"
      atom_id = :project_name

      token = Token.new_for_app_installation!(install_id, nil, atom_id)
      conn = conn(:post, "/", %{"peek-auth" => token})

      conn = PeekAuth.set_peek_install_id(conn, config_id: atom_id)

      assert conn.assigns.peek_install_id == install_id
      assert conn.assigns.peek_install_token == token
      assert conn.assigns.peek_config_id == atom_id

      # Don't test session in tests since it's not properly initialized
    end

    test "has the correct account_user infos" do
      install_id = "test_install_id"

      token =
        Token.new_for_app_installation!(install_id, %{
          email: "test@example.com",
          id: "user123",
          is_peek_admin: true,
          name: "Test User",
          primary_role: "admin"
        })

      conn = conn(:post, "/", %{"peek-auth" => token})

      conn = PeekAuth.set_peek_install_id(conn, %{})
      assert conn.assigns.peek_account_user.email == "test@example.com"
      assert conn.assigns.peek_account_user.id == "user123"
      assert conn.assigns.peek_account_user.is_peek_admin == true
      assert conn.assigns.peek_account_user.name == "Test User"
      assert conn.assigns.peek_account_user.primary_role == "admin"
    end

    test "sets install ID from body params with map options" do
      install_id = "test_install_id"
      atom_id = :project_name

      token = Token.new_for_app_installation!(install_id, nil, atom_id)
      conn = conn(:post, "/", %{"peek-auth" => token})

      conn = PeekAuth.set_peek_install_id(conn, %{config_id: atom_id})

      assert conn.assigns.peek_install_id == install_id
      assert conn.assigns.peek_install_token == token
      assert conn.assigns.peek_config_id == atom_id
    end

    test "sets install ID from query params" do
      install_id = "test_install_id"
      token = Token.new_for_app_installation!(install_id)
      conn = conn(:get, "/")
      conn = %{conn | params: %{"peek-auth" => token}}

      conn = PeekAuth.set_peek_install_id(conn, %{})

      assert conn.assigns.peek_install_id == install_id
      assert conn.assigns.peek_install_token == token

      # Don't test session in tests since it's not properly initialized
    end

    test "sets install ID from header" do
      install_id = "test_install_id"
      token = Token.new_for_app_installation!(install_id)

      conn =
        conn(:get, "/")
        |> put_req_header("x-peek-auth", "Bearer #{token}")

      conn = PeekAuth.set_peek_install_id(conn, %{})

      assert conn.assigns.peek_install_id == install_id
      assert conn.assigns.peek_install_token == token

      # Don't test session in tests since it's not properly initialized
    end

    test "does nothing with invalid token" do
      conn =
        conn(:get, "/")
        |> put_req_header("x-peek-auth", "Bearer invalid_token")

      conn = PeekAuth.set_peek_install_id(conn, %{})

      refute Map.has_key?(conn.assigns, :peek_install_id)
      refute Map.has_key?(conn.assigns, :peek_install_token)
    end

    test "does nothing without token" do
      conn = conn(:get, "/")

      conn = PeekAuth.set_peek_install_id(conn, %{})

      refute Map.has_key?(conn.assigns, :peek_install_id)
      refute Map.has_key?(conn.assigns, :peek_install_token)
    end

    test "sets account_user from claims" do
      install_id = "test_install_id"

      # Create a token with account user information
      account_user = %PeekAppSDK.AccountUser{
        email: "test@example.com",
        id: "user123",
        is_peek_admin: true,
        name: "Test User",
        primary_role: "admin"
      }

      token = Token.new_for_app_installation!(install_id, account_user)
      conn = conn(:post, "/", %{"peek-auth" => token})

      conn = PeekAuth.set_peek_install_id(conn, %{})

      assert conn.assigns.peek_install_id == install_id
      assert conn.assigns.peek_account_user.email == "test@example.com"
      assert conn.assigns.peek_account_user.id == "user123"
      assert conn.assigns.peek_account_user.is_peek_admin == true
      assert conn.assigns.peek_account_user.name == "Test User"
      assert conn.assigns.peek_account_user.primary_role == "admin"
    end

    test "handles missing account user fields in claims" do
      install_id = "test_install_id"

      # Create a token with minimal claims
      config = PeekAppSDK.Config.get_config()
      shared_secret_key = config.peek_app_secret
      signer = Joken.Signer.create("HS256", shared_secret_key)

      params = %{
        "iss" => "peek_app_sdk",
        "sub" => install_id,
        "exp" => DateTime.utc_now() |> DateTime.add(60) |> DateTime.to_unix()
        # No account user fields
      }

      {:ok, token, _claims} = Token.generate_and_sign(params, signer)
      conn = conn(:post, "/", %{"peek-auth" => token})

      conn = PeekAuth.set_peek_install_id(conn, %{})

      assert conn.assigns.peek_install_id == install_id
      assert conn.assigns.peek_account_user == nil
    end

    test "handles legacy account user format with is_admin field" do
      install_id = "test_install_id"

      # Create a token with legacy format (is_admin instead of primary_role)
      config = PeekAppSDK.Config.get_config()
      shared_secret_key = config.peek_app_secret
      signer = Joken.Signer.create("HS256", shared_secret_key)

      params = %{
        "iss" => "peek_app_sdk",
        "sub" => install_id,
        "exp" => DateTime.utc_now() |> DateTime.add(60) |> DateTime.to_unix(),
        "user" => %{
          "email" => "legacy@example.com",
          "id" => "legacy123",
          "is_admin" => true,
          "name" => "Legacy User"
        }
      }

      {:ok, token, _claims} = Token.generate_and_sign(params, signer)
      conn = conn(:post, "/", %{"peek-auth" => token})

      conn = PeekAuth.set_peek_install_id(conn, %{})

      assert conn.assigns.peek_install_id == install_id
      assert conn.assigns.peek_account_user.email == "legacy@example.com"
      assert conn.assigns.peek_account_user.id == "legacy123"
      assert conn.assigns.peek_account_user.is_peek_admin == true
      assert conn.assigns.peek_account_user.name == "Legacy User"
      assert conn.assigns.peek_account_user.primary_role == nil
    end

    test "handles non-keyword list and non-map options" do
      install_id = "test_install_id"
      token = Token.new_for_app_installation!(install_id)

      conn =
        conn(:get, "/")
        |> put_req_header("x-peek-auth", "Bearer #{token}")

      # Pass a string instead of keyword list or map to test the default case
      conn = PeekAuth.set_peek_install_id(conn, "invalid_opts")

      assert conn.assigns.peek_install_id == install_id
    end
  end

  describe "on_mount/4" do
    test "assigns peek_install_id to socket when present in session" do
      install_id = "test_install_id"
      socket = %Phoenix.LiveView.Socket{}
      session = %{"peek_install_id" => install_id}

      assert {:cont, socket} =
               PeekAuth.on_mount(:set_install_id_for_live_view, %{}, session, socket)

      assert socket.assigns.peek_install_id == install_id
    end

    test "assigns peek_install_id and peek_config_id to socket when both present in session" do
      install_id = "test_install_id"
      config_id = "custom"
      socket = %Phoenix.LiveView.Socket{}
      session = %{"peek_install_id" => install_id, "peek_config_id" => config_id}

      assert {:cont, socket} =
               PeekAuth.on_mount(:set_install_id_for_live_view, %{}, session, socket)

      assert socket.assigns.peek_install_id == install_id
      assert socket.assigns.peek_config_id == config_id
    end

    test "assigns peek_install_id and tuple peek_config_id to socket" do
      install_id = "test_install_id"
      config_id = {:project, :project_name}
      socket = %Phoenix.LiveView.Socket{}
      session = %{"peek_install_id" => install_id, "peek_config_id" => config_id}

      assert {:cont, socket} =
               PeekAuth.on_mount(:set_install_id_for_live_view, %{}, session, socket)

      assert socket.assigns.peek_install_id == install_id
      assert socket.assigns.peek_config_id == config_id
    end

    test "assigns peek_install_id and atom peek_config_id to socket" do
      install_id = "test_install_id"
      config_id = :project_name
      socket = %Phoenix.LiveView.Socket{}
      session = %{"peek_install_id" => install_id, "peek_config_id" => config_id}

      assert {:cont, socket} =
               PeekAuth.on_mount(:set_install_id_for_live_view, %{}, session, socket)

      assert socket.assigns.peek_install_id == install_id
      assert socket.assigns.peek_config_id == config_id
    end

    test "does nothing when peek_install_id is not in session" do
      socket = %Phoenix.LiveView.Socket{}
      session = %{}

      assert {:cont, socket} =
               PeekAuth.on_mount(:set_install_id_for_live_view, %{}, session, socket)

      refute Map.has_key?(socket.assigns, :peek_install_id)
      refute Map.has_key?(socket.assigns, :peek_config_id)
    end
  end
end
