defmodule PeekAppSDK.Token do
  use Joken.Config

  def token_config, do: default_claims(default_exp: 60 * 60, skip: [:iss])

  def verify_peek_auth(token) do
    shared_secret_key = Application.fetch_env!(:peek_app_sdk, :peek_app_secret)
    signer = Joken.Signer.create("HS256", shared_secret_key)

    case verify(token, signer) do
      {:ok, %{"sub" => sub}} ->
        {:ok, sub}

      _ ->
        {:error, :unauthorized}
    end
  end

  def new_for_app_installation!(install_id) do
    shared_secret_key = Application.fetch_env!(:peek_app_sdk, :peek_app_secret)
    signer = Joken.Signer.create("HS256", shared_secret_key)

    params = %{
      "iss" => "peek_app_sdk",
      "sub" => install_id,
      "exp" => DateTime.utc_now() |> DateTime.add(60) |> DateTime.to_unix()
    }

    {:ok, token, _claims} = generate_and_sign(params, signer)

    token
  end
end
