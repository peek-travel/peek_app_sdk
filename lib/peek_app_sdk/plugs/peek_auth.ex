defmodule PeekAppSDK.Plugs.PeekAuth do
  import Plug.Conn

  def allow_peek_iframe(conn, _params) do
    put_resp_header(conn, "content-security-policy", "frame-ancestors 'self' *")
  end

  def set_peek_install_id(%{body_params: %{"peek-auth" => token}} = conn, _params),
    do: do_set(conn, token)

  def set_peek_install_id(%{params: %{"peek-auth" => token}} = conn, _params),
    do: do_set(conn, token)

  def set_peek_install_id(conn, _params) do
    with ["Bearer " <> token] <- Plug.Conn.get_req_header(conn, "x-peek-auth") do
      do_set(conn, token)
    else
      _ ->
        conn
    end
  end

  defp do_set(conn, token) do
    with {:ok, install_id, claims} <- PeekAppSDK.Token.verify_peek_auth(token) do
      conn
      |> assign(:peek_install_token, token)
      |> assign(:peek_install_id, install_id)
      |> assign(:peek_account_user, build_account_user(claims))
      |> fetch_session()
      |> put_session(:peek_install_id, install_id)
    else
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

  def on_mount(:set_install_id_for_live_view, _params, params, socket) do
    socket =
      case params do
        %{"peek_install_id" => peek_install_id} ->
          Phoenix.Component.assign(socket, :peek_install_id, peek_install_id)

        %{} ->
          socket
      end

    {:cont, socket}
  end
end
