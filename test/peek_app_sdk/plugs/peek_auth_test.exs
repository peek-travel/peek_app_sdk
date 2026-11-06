defmodule PeekAppSDK.Plugs.PeekAuthTest do
  use ExUnit.Case, async: true

  import Plug.Test
  import Plug.Conn
  import ExUnit.CaptureLog

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
      assert is_map(conn.assigns.peek_verified_claims)
      assert conn.assigns.peek_verified_claims["sub"] == install_id

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
      assert conn.assigns.peek_account_user.locale == nil
    end

    test "extracts locale from user JWT claims into account_user" do
      install_id = "test_install_id"

      config = PeekAppSDK.Config.get_config()
      shared_secret_key = config.peek_app_secret
      signer = Joken.Signer.create("HS256", shared_secret_key)

      params = %{
        "iss" => "app_registry_v2",
        "sub" => install_id,
        "exp" => DateTime.utc_now() |> DateTime.add(60) |> DateTime.to_unix(),
        "user" => %{
          "email" => "user@example.com",
          "id" => "user123",
          "is_admin" => false,
          "name" => "Test User",
          "locale" => "fr"
        }
      }

      {:ok, token, _claims} = Token.generate_and_sign(params, signer)
      conn = conn(:post, "/", %{"peek-auth" => token})

      conn = PeekAuth.set_peek_install_id(conn, %{})

      assert conn.assigns.peek_account_user.locale == "fr"
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

  describe "require_signed_install_webhook/2" do
    @install_id "install_abc"

    defp sign(claims, secret \\ PeekAppSDK.Config.get_config().peek_app_secret) do
      signer = Joken.Signer.create("HS256", secret)
      {:ok, token, _claims} = Token.generate_and_sign(claims, signer)
      token
    end

    defp future_exp, do: DateTime.utc_now() |> DateTime.add(60) |> DateTime.to_unix()

    defp webhook(body, headers \\ []) do
      conn = conn(:post, "/", body)
      %{conn | req_headers: conn.req_headers ++ headers}
    end

    defp bearer(token), do: [{"x-peek-auth", "Bearer " <> token}]

    # Runs the plug and returns the conn and the warning lines it logged.
    defp run_plug(conn, opts \\ []) do
      {result, log} =
        with_log([level: :warning], fn -> PeekAuth.require_signed_install_webhook(conn, opts) end)

      warnings = log |> String.split("\n") |> Enum.filter(&String.contains?(&1, "[warning]"))
      {result, warnings, log}
    end

    defp assert_rejected(conn, reason, opts \\ []) do
      {result, warnings, log} = run_plug(conn, opts)

      assert result.halted
      assert result.status == 401
      assert result.resp_body == "Unauthorized."
      assert [line] = warnings
      assert line =~ "Signed install webhook rejected"
      assert line =~ reason
      refute log =~ @install_id

      for {"x-peek-auth", "Bearer " <> token} <- conn.req_headers, token != "" do
        refute log =~ token
      end

      result
    end

    test "passes a real token for the body install_id" do
      token = Token.new_for_app_installation!(@install_id)
      conn = webhook(%{"install_id" => @install_id}, bearer(token))

      {result, warnings, _log} = run_plug(conn)

      refute result.halted
      assert result.status == nil
      assert result.assigns == %{}
      assert warnings == []
    end

    test "passes with a config_id as a keyword list and as a map" do
      token = Token.new_for_app_installation!(@install_id, nil, :project_name)
      conn = webhook(%{"install_id" => @install_id}, bearer(token))

      {result, [], _log} = run_plug(conn, config_id: :project_name)
      refute result.halted

      {result, [], _log} = run_plug(conn, %{config_id: :project_name})
      refute result.halted
    end

    test "treats options that are not a list or a map as the default config" do
      token = Token.new_for_app_installation!(@install_id)
      conn = webhook(%{"install_id" => @install_id}, bearer(token))

      {result, [], _log} = run_plug(conn, nil)
      refute result.halted
    end

    test "rejects a request with no X-Peek-Auth header" do
      assert_rejected(webhook(%{"install_id" => @install_id}), "missing token")
    end

    test "rejects a header with no Bearer token" do
      assert_rejected(webhook(%{"install_id" => @install_id}, [{"x-peek-auth", "Bearer "}]), "missing token")
    end

    test "rejects a header with no Bearer prefix" do
      token = Token.new_for_app_installation!(@install_id)
      assert_rejected(webhook(%{"install_id" => @install_id}, [{"x-peek-auth", token}]), "missing token")
    end

    test "rejects two X-Peek-Auth headers" do
      token = Token.new_for_app_installation!(@install_id)
      conn = webhook(%{"install_id" => @install_id}, bearer(token) ++ bearer(token))

      assert_rejected(conn, "missing token")
    end

    test "rejects a token in a body param" do
      token = Token.new_for_app_installation!(@install_id)
      assert_rejected(webhook(%{"install_id" => @install_id, "peek-auth" => token}), "missing token")
    end

    test "rejects a token in a query param" do
      token = Token.new_for_app_installation!(@install_id)

      conn =
        conn(:post, "/?peek-auth=#{token}", %{"install_id" => @install_id})
        |> fetch_query_params()

      assert_rejected(conn, "missing token")
    end

    test "rejects a token that is not a JWT" do
      assert_rejected(webhook(%{"install_id" => @install_id}, bearer("invalid_token")), "invalid token")
    end

    test "rejects a token signed with another secret" do
      token = sign(%{"sub" => @install_id, "exp" => future_exp()}, "another_secret")
      assert_rejected(webhook(%{"install_id" => @install_id}, bearer(token)), "invalid token")
    end

    test "rejects a token for the config of another app" do
      token = Token.new_for_app_installation!(@install_id)
      conn = webhook(%{"install_id" => @install_id}, bearer(token))

      assert_rejected(conn, "invalid token", config_id: :project_name)
    end

    test "rejects an expired token" do
      token = sign(%{"sub" => @install_id, "exp" => DateTime.utc_now() |> DateTime.add(-60) |> DateTime.to_unix()})
      assert_rejected(webhook(%{"install_id" => @install_id}, bearer(token)), "invalid token")
    end

    test "rejects a token with no sub" do
      token = sign(%{"exp" => future_exp()})
      assert_rejected(webhook(%{"install_id" => @install_id}, bearer(token)), "invalid token")
    end

    test "rejects a token with a sub that is not a string" do
      token = sign(%{"sub" => 123, "exp" => future_exp()})
      assert_rejected(webhook(%{"install_id" => "123"}, bearer(token)), "invalid token")
    end

    test "rejects a token for another install" do
      token = Token.new_for_app_installation!("another_install")
      assert_rejected(webhook(%{"install_id" => @install_id}, bearer(token)), "install mismatch")
    end

    test "rejects a body with no install_id" do
      token = Token.new_for_app_installation!(@install_id)
      assert_rejected(webhook(%{}, bearer(token)), "missing install_id")
    end

    test "rejects an empty install_id" do
      token = Token.new_for_app_installation!(@install_id)
      assert_rejected(webhook(%{"install_id" => ""}, bearer(token)), "missing install_id")
    end

    test "rejects an install_id that is not a string" do
      token = Token.new_for_app_installation!(@install_id)
      assert_rejected(webhook(%{"install_id" => [@install_id]}, bearer(token)), "missing install_id")
    end

    test "rejects an install_id that is only in the query string" do
      token = Token.new_for_app_installation!(@install_id)

      conn =
        conn(:post, "/?install_id=#{@install_id}", %{})
        |> fetch_query_params()
        |> put_req_header("x-peek-auth", "Bearer " <> token)

      assert_rejected(conn, "missing install_id")
    end

    test "rejects a request with a body that is not parsed" do
      token = Token.new_for_app_installation!(@install_id)
      conn = conn(:post, "/") |> put_req_header("x-peek-auth", "Bearer " <> token)

      assert %Plug.Conn.Unfetched{} = conn.body_params
      assert_rejected(conn, "missing install_id")
    end

    test "does not change set_peek_install_id assigns that are already set" do
      token = Token.new_for_app_installation!("another_install")

      conn = assign(webhook(%{"install_id" => @install_id}, bearer(token)), :peek_install_id, @install_id)

      result = assert_rejected(conn, "install mismatch")
      assert result.assigns.peek_install_id == @install_id
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
