defmodule PeekAppSDK.Plugs.ClientAuthTest do
  use ExUnit.Case, async: true

  import Plug.Test
  import Plug.Conn

  alias PeekAppSDK.Plugs.ClientAuth
  alias PeekAppSDK.Token

  # Helper function to create client tokens for testing
  defp new_client_token(install_id, _account_user \\ nil, config_id \\ nil), do:
    PeekAppSDK.Token.new_for_app_installation_client(install_id, config_id)

  describe "set_peek_install_id_from_client/2" do
    test "sets install ID from header with default config" do
      install_id = "test_install_id"
      token = new_client_token(install_id)

      conn =
        conn(:get, "/")
        |> put_req_header("x-peek-auth", "Bearer #{token}")

      conn = ClientAuth.set_peek_install_id_from_client(conn, %{})

      assert conn.assigns.peek_install_id == install_id
      assert conn.assigns.peek_install_token == token
      assert conn.assigns.peek_config_id == nil
    end

    test "sets install ID from header with atom config_id" do
      install_id = "test_install_id"
      atom_id = :project_name

      token = new_client_token(install_id, nil, atom_id)

      conn =
        conn(:get, "/")
        |> put_req_header("x-peek-auth", "Bearer #{token}")

      conn = ClientAuth.set_peek_install_id_from_client(conn, config_id: atom_id)

      assert conn.assigns.peek_install_id == install_id
      assert conn.assigns.peek_install_token == token
      assert conn.assigns.peek_config_id == atom_id
    end

    test "does not have account_user info; it's a client not a peek pro user" do
      install_id = "test_install_id"

      token =
        new_client_token(install_id, %{
          email: "test@example.com",
          id: "user123",
          is_peek_admin: true,
          name: "Test User",
          primary_role: "admin"
        })

      conn =
        conn(:get, "/")
        |> put_req_header("x-peek-auth", "Bearer #{token}")

      conn = ClientAuth.set_peek_install_id_from_client(conn, %{})
      assert conn.assigns.peek_account_user.email == nil
      assert conn.assigns.peek_account_user.id == nil
      assert conn.assigns.peek_account_user.is_peek_admin == nil
      assert conn.assigns.peek_account_user.name == nil
      assert conn.assigns.peek_account_user.primary_role == nil
    end

    test "sets install ID from header with map options" do
      install_id = "test_install_id"
      atom_id = :project_name

      token = new_client_token(install_id, nil, atom_id)

      conn =
        conn(:get, "/")
        |> put_req_header("x-peek-auth", "Bearer #{token}")

      conn = ClientAuth.set_peek_install_id_from_client(conn, %{config_id: atom_id})

      assert conn.assigns.peek_install_id == install_id
      assert conn.assigns.peek_install_token == token
      assert conn.assigns.peek_config_id == atom_id
    end

    test "does nothing with invalid token" do
      conn =
        conn(:get, "/")
        |> put_req_header("x-peek-auth", "Bearer invalid_token")

      conn = ClientAuth.set_peek_install_id_from_client(conn, %{})

      refute Map.has_key?(conn.assigns, :peek_install_id)
      refute Map.has_key?(conn.assigns, :peek_install_token)
    end

    test "does nothing without token" do
      conn = conn(:get, "/")

      conn = ClientAuth.set_peek_install_id_from_client(conn, %{})

      refute Map.has_key?(conn.assigns, :peek_install_id)
      refute Map.has_key?(conn.assigns, :peek_install_token)
    end

    test "does nothing when client_secret_token is not configured" do
      install_id = "test_install_id"
      # Use other_app which doesn't have client_secret_token configured
      token = Token.new_for_app_installation!(install_id, nil, :other_app)

      conn =
        conn(:get, "/")
        |> put_req_header("x-peek-auth", "Bearer #{token}")

      conn = ClientAuth.set_peek_install_id_from_client(conn, config_id: :other_app)

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

      token = new_client_token(install_id, account_user)

      conn =
        conn(:get, "/")
        |> put_req_header("x-peek-auth", "Bearer #{token}")

      conn = ClientAuth.set_peek_install_id_from_client(conn, %{})

      assert conn.assigns.peek_install_id == install_id
      assert conn.assigns.peek_account_user.email == nil
      assert conn.assigns.peek_account_user.id == nil
      assert conn.assigns.peek_account_user.is_peek_admin == nil
      assert conn.assigns.peek_account_user.name == nil
      assert conn.assigns.peek_account_user.primary_role == nil
    end

    test "handles missing account user fields in claims" do
      install_id = "test_install_id"

      # Create a token with minimal claims using client_secret_token
      config = PeekAppSDK.Config.get_config()
      client_secret_key = config.client_secret_token
      signer = Joken.Signer.create("HS256", client_secret_key)

      params = %{
        "iss" => "peek_app_sdk",
        "sub" => install_id,
        "exp" => DateTime.utc_now() |> DateTime.add(60) |> DateTime.to_unix()
        # No account user fields
      }

      {:ok, token, _claims} = Token.generate_and_sign(params, signer)

      conn =
        conn(:get, "/")
        |> put_req_header("x-peek-auth", "Bearer #{token}")

      conn = ClientAuth.set_peek_install_id_from_client(conn, %{})

      assert conn.assigns.peek_install_id == install_id
      assert conn.assigns.peek_account_user == nil
    end
  end

  describe "on_mount/4" do
    test "assigns peek_install_id to socket when present in session" do
      install_id = "test_install_id"
      socket = %Phoenix.LiveView.Socket{}
      session = %{"peek_install_id" => install_id}

      assert {:cont, socket} =
               ClientAuth.on_mount(:set_install_id_for_live_view, %{}, session, socket)

      assert socket.assigns.peek_install_id == install_id
    end

    test "assigns peek_install_id and peek_config_id to socket when both present in session" do
      install_id = "test_install_id"
      config_id = "custom"
      socket = %Phoenix.LiveView.Socket{}
      session = %{"peek_install_id" => install_id, "peek_config_id" => config_id}

      assert {:cont, socket} =
               ClientAuth.on_mount(:set_install_id_for_live_view, %{}, session, socket)

      assert socket.assigns.peek_install_id == install_id
      assert socket.assigns.peek_config_id == config_id
    end

    test "assigns peek_install_id and tuple peek_config_id to socket" do
      install_id = "test_install_id"
      config_id = {:project, :project_name}
      socket = %Phoenix.LiveView.Socket{}
      session = %{"peek_install_id" => install_id, "peek_config_id" => config_id}

      assert {:cont, socket} =
               ClientAuth.on_mount(:set_install_id_for_live_view, %{}, session, socket)

      assert socket.assigns.peek_install_id == install_id
      assert socket.assigns.peek_config_id == config_id
    end

    test "assigns peek_install_id and atom peek_config_id to socket" do
      install_id = "test_install_id"
      config_id = :project_name
      socket = %Phoenix.LiveView.Socket{}
      session = %{"peek_install_id" => install_id, "peek_config_id" => config_id}

      assert {:cont, socket} =
               ClientAuth.on_mount(:set_install_id_for_live_view, %{}, session, socket)

      assert socket.assigns.peek_install_id == install_id
      assert socket.assigns.peek_config_id == config_id
    end

    test "does nothing when peek_install_id is not in session" do
      socket = %Phoenix.LiveView.Socket{}
      session = %{}

      assert {:cont, socket} =
               ClientAuth.on_mount(:set_install_id_for_live_view, %{}, session, socket)

      refute Map.has_key?(socket.assigns, :peek_install_id)
      refute Map.has_key?(socket.assigns, :peek_config_id)
    end
  end
end
