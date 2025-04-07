defmodule PeekAppSDK.Token do
  use Joken.Config

  alias PeekAppSDK.AccountUser
  alias PeekAppSDK.Config

  def token_config, do: default_claims(default_exp: 60 * 60, skip: [:iss])

  @doc """
  Verifies a peek authentication token.

  ## Examples

  Using the default configuration:

      iex> PeekAppSDK.Token.verify_peek_auth(token)
      {:ok, "install_id"}

  Using a specific application's configuration:

      iex> PeekAppSDK.Token.verify_peek_auth(token, :semnox)
      {:ok, "install_id"}
  """
  @spec verify_peek_auth(String.t(), atom() | nil) :: {:ok, String.t()} | {:error, :unauthorized}
  def verify_peek_auth(token, config_id \\ nil) do
    config = Config.get_config(config_id)
    shared_secret_key = config.peek_app_secret
    signer = Joken.Signer.create("HS256", shared_secret_key)

    case verify_and_validate(token, signer) do
      {:ok, %{"sub" => sub} = claims} ->
        {:ok, sub, claims}

      {:error, _reason} ->
        {:error, :unauthorized}

      _ ->
        {:error, :unauthorized}
    end
  end

  @doc """
  Generates a new token for an app installation.

  ## Examples

  Using the default configuration:

      iex> PeekAppSDK.Token.new_for_app_installation!("install_id")
      "token"

  Using a specific application's configuration:

      iex> PeekAppSDK.Token.new_for_app_installation!("install_id", :semnox)
      "token"
  """
  @spec new_for_app_installation!(String.t(), map() | nil, atom() | nil) :: String.t()
  def new_for_app_installation!(install_id, account_user \\ nil, config_id \\ nil) do
    config = Config.get_config(config_id)
    shared_secret_key = config.peek_app_secret

    signer = Joken.Signer.create("HS256", shared_secret_key)
    account_user = account_user || AccountUser.hook()

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
