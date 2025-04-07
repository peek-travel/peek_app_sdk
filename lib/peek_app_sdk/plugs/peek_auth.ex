defmodule PeekAppSDK.Plugs.PeekAuth do
  import Plug.Conn

  @doc """
  Allows Peek iframe embedding by setting appropriate CSP headers.
  """
  def allow_peek_iframe(conn, _params) do
    put_resp_header(conn, "content-security-policy", "frame-ancestors 'self' *")
  end

  @doc """
  Sets the peek_install_id in the connection assigns based on the token in the request.

  ## Options

  * `:config_id` - The configuration identifier to use for token verification. Defaults to nil (use default config).

  ## Examples

      # Using default configuration
      plug :set_peek_install_id

      # Using a specific configuration with a string identifier (legacy approach)
      plug :set_peek_install_id, config_id: "my_app"

      # Using a specific configuration with a tuple identifier (recommended approach)
      plug :set_peek_install_id, config_id: {:project, :semnox}
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

      _ ->
        conn
    end
  end

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

  defp build_account_user(_), do: nil

  @doc """
  LiveView on_mount callback to set the peek_install_id in the socket assigns.

  ## Options

  * `:config_id` - The configuration identifier to use. Defaults to nil (use default config).

  ## Examples

      # Using default configuration
      live_session :some_scope, on_mount: {PeekAppSDK.Plugs.PeekAuth, :set_install_id_for_live_view}

      # Using a specific configuration with a string identifier (legacy approach)
      live_session :some_scope, on_mount: [{PeekAppSDK.Plugs.PeekAuth, :set_install_id_for_live_view, [config_id: "my_app"]}]

      # Using a specific configuration with a tuple identifier (recommended approach)
      live_session :some_scope, on_mount: [{PeekAppSDK.Plugs.PeekAuth, :set_install_id_for_live_view, [config_id: {:project, :semnox}]}]
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
