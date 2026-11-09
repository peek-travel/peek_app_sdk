defmodule PeekAppSDK.Plugs.PeekAuthWebhookTest do
  # The tests count the warning lines in the captured log, and one test changes
  # the application env. Other tests log at the same time when they run async.
  use ExUnit.Case, async: false

  import Plug.Test
  import Plug.Conn
  import ExUnit.CaptureLog

  alias PeekAppSDK.Plugs.PeekAuth
  alias PeekAppSDK.Token

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
      assert ["text/plain" <> _] = get_resp_header(result, "content-type")
      assert [line] = warnings
      assert line =~ "Signed install webhook rejected"
      assert line =~ reason
      refute log =~ @install_id

      for {"x-peek-auth", "Bearer " <> token} <- conn.req_headers, token != "" do
        refute log =~ token
      end

      for value <- Map.values(conn.body_params), is_binary(value), value != "" do
        refute log =~ value
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

    test "raises for a config_id that has no app config" do
      token = Token.new_for_app_installation!(@install_id)
      conn = webhook(%{"install_id" => @install_id}, bearer(token))

      assert_raise ArgumentError, ~r/no app config for :unknown_app/, fn ->
        PeekAuth.require_signed_install_webhook(conn, config_id: :unknown_app)
      end
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
      assert_rejected(webhook(%{"install_id" => "install_123"}, bearer(token)), "invalid token")
    end

    test "rejects a token for another install" do
      token = Token.new_for_app_installation!("another_install")
      assert_rejected(webhook(%{"install_id" => @install_id}, bearer(token)), "install_id mismatch")
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

      result = assert_rejected(conn, "install_id mismatch")
      assert result.assigns.peek_install_id == @install_id
    end
  end

  describe "require_signed_install_webhook/2 with no app secret" do
    setup do
      secret = Application.get_env(:peek_app_sdk, :peek_app_secret)
      on_exit(fn -> Application.put_env(:peek_app_sdk, :peek_app_secret, secret) end)
    end

    test "rejects the request when the config has no app secret" do
      Application.delete_env(:peek_app_sdk, :peek_app_secret)
      assert_rejected_without_secret()
    end

    test "rejects the request when the app secret is empty" do
      Application.put_env(:peek_app_sdk, :peek_app_secret, "")
      assert_rejected_without_secret()
    end

    defp assert_rejected_without_secret do
      conn =
        conn(:post, "/", %{"install_id" => "install_abc"})
        |> put_req_header("x-peek-auth", "Bearer some_token")

      log =
        capture_log([level: :warning], fn ->
          conn = PeekAuth.require_signed_install_webhook(conn, [])

          assert conn.halted
          assert conn.status == 401
        end)

      assert log =~ "Signed install webhook rejected for config_id=nil: invalid token"
      refute log =~ "some_token"
      refute log =~ "install_abc"
    end
  end
end
