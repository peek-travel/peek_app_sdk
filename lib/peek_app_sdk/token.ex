defmodule PeekAppSDK.Token do
  use Joken.Config

  def token_config, do: default_claims(default_exp: 60 * 60, skip: [:iss])

  def verify_peek_auth(token) do
    shared_secret_key = Application.fetch_env!(:peek_app_sdk, :peek_app_secret)
    signer = Joken.Signer.create("HS256", shared_secret_key)

    case verify(token, signer) do
      {:ok, %{"sub" => sub} = claims} ->
        {:ok, sub, claims}

      _ ->
        {:error, :unauthorized}
    end
  end

  def new_for_app_installation!(install_id, account_user \\ nil) do
    shared_secret_key = Application.fetch_env!(:peek_app_sdk, :peek_app_secret)
    signer = Joken.Signer.create("HS256", shared_secret_key)
    account_user = account_user || PeekAppSDK.AccountUser.hook()

    params = %{
      "iss" => "peek_app_sdk",
      "sub" => install_id,
      "exp" => DateTime.utc_now() |> DateTime.add(60) |> DateTime.to_unix(),
      "current_user_email" => account_user.email,
      "current_user_id" => account_user.id,
      "current_user_is_peek_admin" => account_user.is_peek_admin,
      "current_user_name" => account_user.name,
      "current_user_primary_role" => account_user.primary_role
    }

    {:ok, token, _claims} = generate_and_sign(params, signer)

    token
  end
end
