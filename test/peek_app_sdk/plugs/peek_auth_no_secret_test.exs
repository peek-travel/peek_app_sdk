defmodule PeekAppSDK.Plugs.PeekAuthNoSecretTest do
  # Changes the application env, so it cannot run async.
  use ExUnit.Case, async: false

  import Plug.Test
  import Plug.Conn
  import ExUnit.CaptureLog

  alias PeekAppSDK.Plugs.PeekAuth

  setup do
    secret = Application.get_env(:peek_app_sdk, :peek_app_secret)
    Application.delete_env(:peek_app_sdk, :peek_app_secret)
    on_exit(fn -> Application.put_env(:peek_app_sdk, :peek_app_secret, secret) end)
  end

  test "require_signed_install_webhook/2 rejects the request when the config has no app secret" do
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
  end
end
