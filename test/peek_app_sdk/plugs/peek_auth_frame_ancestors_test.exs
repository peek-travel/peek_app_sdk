defmodule PeekAppSDK.Plugs.PeekAuthFrameAncestorsTest do
  # Changes the :peek_app_sdk app env, so it cannot run async.
  use ExUnit.Case, async: false

  import Plug.Test
  import Plug.Conn

  alias PeekAppSDK.Plugs.PeekAuth

  setup do
    on_exit(fn -> Application.delete_env(:peek_app_sdk, :extra_frame_ancestors) end)
  end

  defp csp_with_extra(extra) do
    Application.put_env(:peek_app_sdk, :extra_frame_ancestors, extra)
    conn = PeekAuth.allow_peek_iframe(conn(:get, "/"), %{})
    get_resp_header(conn, "content-security-policy")
  end

  test "adds the extra origins after the Peek origins" do
    assert csp_with_extra(["https://partner.example.com", "https://app.example.org:8443", "http://localhost:4000"]) ==
             [
               "frame-ancestors 'self' https://*.peek.com https://*.peeklabs.com " <>
                 "https://partner.example.com https://app.example.org:8443 http://localhost:4000"
             ]
  end

  test "an empty list keeps only the Peek origins" do
    assert csp_with_extra([]) == ["frame-ancestors 'self' https://*.peek.com https://*.peeklabs.com"]
  end

  test "nil keeps only the Peek origins" do
    assert csp_with_extra(nil) == ["frame-ancestors 'self' https://*.peek.com https://*.peeklabs.com"]
  end

  test "accepts the lowest and the highest port" do
    assert [header] = csp_with_extra(["https://a.example.com:1", "https://b.example.com:65535"])
    assert String.ends_with?(header, " https://a.example.com:1 https://b.example.com:65535")
  end

  test "lists an origin only one time" do
    assert csp_with_extra(["https://p.example.com", "https://p.example.com"]) == [
             "frame-ancestors 'self' https://*.peek.com https://*.peeklabs.com https://p.example.com"
           ]
  end

  test "frame_ancestors/0 returns the Peek origins and then the extra origins" do
    Application.put_env(:peek_app_sdk, :extra_frame_ancestors, ["https://p-1.example.com"])

    assert PeekAuth.frame_ancestors() == ["https://*.peek.com", "https://*.peeklabs.com", "https://p-1.example.com"]
  end

  test "accepts http://127.0.0.1 for local development" do
    assert [header] = csp_with_extra(["http://127.0.0.1"])
    assert String.ends_with?(header, " http://127.0.0.1")
  end

  for bad <- [
        "*",
        "https://*",
        "https://*.example.com",
        "http://partner.example.com",
        "partner.example.com",
        "https://partner.example.com/",
        "https://partner.example.com/path",
        "https://a.example.com https://b.example.com",
        "https://a.example.com,https://b.example.com",
        "https://a.example.com; script-src *",
        "'unsafe-inline'",
        "http://localhost.example.com",
        "https://partner.example.com:",
        "https://partner.example.com:0",
        "https://partner.example.com:65536",
        "https://partner.example.com:99999",
        "https://-partner.example.com",
        "https://partner-.example.com",
        "https://partner..example.com",
        ""
      ] do
    test "raises for the invalid origin #{inspect(bad)}" do
      assert_raise ArgumentError, ~r/invalid origin in config :peek_app_sdk, :extra_frame_ancestors/, fn ->
        csp_with_extra([unquote(bad)])
      end
    end
  end

  test "raises for an origin that is not a string" do
    assert_raise ArgumentError, ~r/invalid origin/, fn -> csp_with_extra([:partner]) end
  end

  test "raises when the config value is not a list" do
    assert_raise ArgumentError, ~r/must be a list of origins/, fn ->
      csp_with_extra("https://partner.example.com")
    end
  end
end
