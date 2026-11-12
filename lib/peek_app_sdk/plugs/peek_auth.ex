defmodule PeekAppSDK.Plugs.PeekAuth do
  import Plug.Conn

  require Logger

  @peek_frame_ancestors ["https://*.peek.com", "https://*.peeklabs.com"]

  # An origin: `https://<host>[:port]`, or `http://localhost[:port]` and
  # `http://127.0.0.1[:port]` for local development. No `*`, path, space,
  # quote, `,` or `;`. A host label does not start or end with `-`.
  @origin_regex ~r/\A(?:https:\/\/[A-Za-z0-9](?:[A-Za-z0-9-]*[A-Za-z0-9])?(?:\.[A-Za-z0-9](?:[A-Za-z0-9-]*[A-Za-z0-9])?)*|http:\/\/(?:localhost|127\.0\.0\.1))(?::([0-9]{1,5}))?\z/

  @doc """
  Lets Peek pages put the app in an iframe.

  Sets the `content-security-policy` response header to
  `frame-ancestors 'self'`, the Peek origins (`peek_frame_ancestors/0`) and the
  origins in `config :peek_app_sdk, :extra_frame_ancestors`.

  The Peek origins are not a full list: each platform environment has its own
  origin. To add origins, set `:extra_frame_ancestors` to a list of origins.
  The plug reads it on each request, so you can set it in `config/runtime.exs`:

      config :peek_app_sdk, :extra_frame_ancestors, ["https://partner.example.com"]

  Each origin must be `https://<host>` with an optional port, or
  `http://localhost` / `http://127.0.0.1` with an optional port. A wildcard,
  a path, a trailing `/` or any other value raises `ArgumentError`. The SDK
  checks the config when it starts too, so a bad value stops the boot.
  """
  def allow_peek_iframe(conn, _params) do
    sources = Enum.join(["'self'" | frame_ancestors()], " ")
    put_resp_header(conn, "content-security-policy", "frame-ancestors " <> sources)
  end

  @doc """
  Returns the origins that `allow_peek_iframe/2` allows after `'self'`: the
  Peek origins, then the `:extra_frame_ancestors` origins, with no duplicates.

  Raises `ArgumentError` when `:extra_frame_ancestors` is not valid.
  """
  @spec frame_ancestors() :: [String.t()]
  def frame_ancestors, do: Enum.uniq(@peek_frame_ancestors ++ extra_frame_ancestors())

  @doc """
  Returns the Peek origins that `allow_peek_iframe/2` always allows.
  """
  @spec peek_frame_ancestors() :: [String.t()]
  def peek_frame_ancestors, do: @peek_frame_ancestors

  defp extra_frame_ancestors do
    case Application.get_env(:peek_app_sdk, :extra_frame_ancestors) do
      nil ->
        []

      origins when is_list(origins) ->
        Enum.map(origins, &validate_frame_ancestor!/1)

      other ->
        raise ArgumentError,
              "config :peek_app_sdk, :extra_frame_ancestors must be a list of origins, got: #{inspect(other)}"
    end
  end

  defp validate_frame_ancestor!(origin) do
    if valid_origin?(origin) do
      origin
    else
      raise ArgumentError,
            "invalid origin in config :peek_app_sdk, :extra_frame_ancestors: #{inspect(origin)}. " <>
              "Use https://<host> with an optional port, or http://localhost or " <>
              "http://127.0.0.1 for local development."
    end
  end

  defp valid_origin?(origin) when is_binary(origin) do
    case Regex.run(@origin_regex, origin) do
      [_origin] -> true
      [_origin, port] -> String.to_integer(port) in 1..65_535
      nil -> false
    end
  end

  defp valid_origin?(_origin), do: false

  @doc """
  Sets the peek_install_id in the connection assigns based on the token in the request.

  ## Options

  * `:config_id` - The configuration identifier to use for token verification: an atom key under `config :peek_app_sdk, :apps`. Defaults to nil (use default config).
    Raises `ArgumentError` when that app config is missing or incomplete (see `PeekAppSDK.Config.get_config/1`).

  ## Examples

      # Using default configuration
      plug :set_peek_install_id

      # Using the configuration of an app under `config :peek_app_sdk, :apps`
      plug :set_peek_install_id, config_id: :project_name
  """
  def set_peek_install_id(%{body_params: %{"peek-auth" => token}} = conn, opts),
    do: do_set(conn, token, opts)

  def set_peek_install_id(%{params: %{"peek-auth" => token}} = conn, opts),
    do: do_set(conn, token, opts)

  def set_peek_install_id(conn, opts) do
    case Plug.Conn.get_req_header(conn, "x-peek-auth") do
      ["Bearer " <> token] -> do_set(conn, token, opts)
      _ -> conn
    end
  end

  defp do_set(conn, token, opts) do
    # Handle both keyword list and map options
    config_id =
      cond do
        is_list(opts) -> Keyword.get(opts, :config_id)
        is_map(opts) -> Map.get(opts, :config_id)
        true -> nil
      end

    case PeekAppSDK.Token.verify_peek_auth(token, config_id) do
      {:ok, install_id, claims} ->
        # Assign values to the connection
        conn
        |> assign(:peek_install_token, token)
        |> assign(:peek_install_id, install_id)
        |> assign(:peek_account_user, build_account_user(claims))
        |> assign(:peek_config_id, config_id)
        |> assign(:peek_verified_claims, claims)

      _ ->
        conn
    end
  end

  @doc """
  Lets a request through only when its `X-Peek-Auth` header has a valid token
  for the `install_id` in the request body.

  The plug reads the token only from the `X-Peek-Auth: Bearer <token>` header.
  It verifies the token with the app secret, then compares the token `sub` to
  the `install_id` in `conn.body_params`. It does not read query params, path
  params, a `peek-auth` body param or the conn assigns.

  When the request passes, the plug returns the conn with no change. Otherwise
  it writes one warning log, sends a 401 response and halts the conn. The log
  line does not contain the token, the `install_id` or the body.

  Put the plug after `Plug.Parsers`, so that the body is parsed. When the
  request passes, the body `install_id` is the install id of the checked token,
  so read the install id from the body. Do not use the assigns of
  `set_peek_install_id` on this route: that plug reads a `peek-auth` body or
  query param before the header, so its assigns can come from another token.

  ## Options

  * `:config_id` - The configuration identifier to use for token verification: an atom key under `config :peek_app_sdk, :apps`. Defaults to nil (use default config).
    Raises `ArgumentError` when that app config is missing or incomplete (see `PeekAppSDK.Config.get_config/1`).

  ## Examples

      # Using default configuration
      plug :require_signed_install_webhook

      # Using a specific application's configuration
      plug :require_signed_install_webhook, config_id: :project_name
  """
  def require_signed_install_webhook(conn, opts) do
    config_id = config_id(opts)

    case check_signed_install_webhook(conn, config_id) do
      :ok ->
        conn

      {:error, reason} ->
        Logger.warning("Signed install webhook rejected for config_id=#{inspect(config_id)}: #{reason}")

        conn
        |> put_resp_content_type("text/plain")
        |> send_resp(:unauthorized, "Unauthorized.")
        |> halt()
    end
  end

  defp check_signed_install_webhook(conn, config_id) do
    with {:ok, token} <- header_token(conn),
         {:ok, install_id} <- body_install_id(conn),
         {:ok, sub} <- token_sub(token, config_id) do
      if sub == install_id, do: :ok, else: {:error, "install_id mismatch"}
    end
  end

  defp config_id(opts) when is_list(opts), do: Keyword.get(opts, :config_id)
  defp config_id(opts) when is_map(opts), do: Map.get(opts, :config_id)
  defp config_id(_opts), do: nil

  defp header_token(conn) do
    case get_req_header(conn, "x-peek-auth") do
      ["Bearer " <> token] when token != "" -> {:ok, token}
      _ -> {:error, "missing token"}
    end
  end

  defp body_install_id(%{body_params: %{"install_id" => install_id}}) when is_binary(install_id) and install_id != "",
    do: {:ok, install_id}

  defp body_install_id(_conn), do: {:error, "missing install_id"}

  defp token_sub(token, config_id) do
    with true <- usable_secret?(PeekAppSDK.Config.get_config(config_id).peek_app_secret),
         {:ok, %{"sub" => sub}} when is_binary(sub) <- PeekAppSDK.Token.verify_peek_auth_claims(token, config_id) do
      {:ok, sub}
    else
      _ -> {:error, "invalid token"}
    end
  end

  defp usable_secret?(secret), do: is_binary(secret) and secret != ""

  defp build_account_user(%{
         "current_user_email" => current_user_email,
         "current_user_id" => current_user_id,
         "current_user_is_peek_admin" => current_user_is_peek_admin,
         "current_user_name" => current_user_name,
         "current_user_primary_role" => current_user_primary_role
       }) do
    %PeekAppSDK.AccountUser{
      email: current_user_email,
      id: current_user_id,
      is_peek_admin: current_user_is_peek_admin,
      name: current_user_name,
      primary_role: current_user_primary_role
    }
  end

  defp build_account_user(%{
         "user" =>
           %{
             "id" => current_user_id,
             "email" => current_user_email,
             "is_admin" => current_user_is_peek_admin,
             "name" => current_user_name
           } = user
       }) do
    %PeekAppSDK.AccountUser{
      email: current_user_email,
      id: current_user_id,
      is_peek_admin: current_user_is_peek_admin,
      name: current_user_name,
      primary_role: nil,
      locale: user["locale"]
    }
  end

  defp build_account_user(_), do: nil

  @doc """
  LiveView on_mount callback to set the peek_install_id in the socket assigns.

  ## Options

  * `:config_id` - The configuration identifier to use: an atom key under `config :peek_app_sdk, :apps`. Defaults to nil (use default config).

  ## Examples

      # Using default configuration
      live_session :some_scope, on_mount: {PeekAppSDK.Plugs.PeekAuth, :set_install_id_for_live_view}

      # Using the configuration of an app under `config :peek_app_sdk, :apps`
      live_session :some_scope, on_mount: [{PeekAppSDK.Plugs.PeekAuth, :set_install_id_for_live_view, [config_id: :project_name]}]
  """
  def on_mount(:set_install_id_for_live_view, _params, session, socket) do
    socket =
      case session do
        %{"peek_install_id" => peek_install_id, "peek_config_id" => config_id} ->
          socket
          |> Phoenix.Component.assign(:peek_install_id, peek_install_id)
          |> Phoenix.Component.assign(:peek_config_id, config_id)

        %{"peek_install_id" => peek_install_id} ->
          Phoenix.Component.assign(socket, :peek_install_id, peek_install_id)

        %{} ->
          socket
      end

    {:cont, socket}
  end
end
