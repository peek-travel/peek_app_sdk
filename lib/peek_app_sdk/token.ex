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

      iex> PeekAppSDK.Token.verify_peek_auth(token, :project_name)
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
  Verifies a client request token using the client_secret_token.

  ## Examples

  Using the default configuration:

      iex> PeekAppSDK.Token.verify_client_request(token)
      {:ok, "install_id"}

  Using a specific application's configuration:

      iex> PeekAppSDK.Token.verify_client_request(token, :project_name)
      {:ok, "install_id"}
  """
  @spec verify_client_request(String.t(), atom() | nil) ::
          {:ok, String.t()} | {:error, :unauthorized}
  def verify_client_request(token, config_id \\ nil) do
    config = Config.get_config(config_id)
    client_secret_key = config.client_secret_token

    # Return error if client_secret_token is not configured
    if client_secret_key do
      signer = Joken.Signer.create("HS256", client_secret_key)

      case verify_and_validate(token, signer) do
        {:ok, %{"sub" => sub} = claims} ->
          {:ok, sub, claims}

        {:error, _reason} ->
          {:error, :unauthorized}

        _ ->
          {:error, :unauthorized}
      end
    else
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

      iex> PeekAppSDK.Token.new_for_app_installation!("install_id", :project_name)
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

  @spec new_for_app_installation_client(String.t(), atom() | nil) :: binary()
  def new_for_app_installation_client(install_id, config_id \\ nil) do
    config = Config.get_config(config_id)
    client_secret_key = config.client_secret_token

    signer = Joken.Signer.create("HS256", client_secret_key)

    params = %{
      "iss" => "app_registry_client",
      "sub" => install_id,
      "exp" => DateTime.utc_now() |> DateTime.add(60) |> DateTime.to_unix(),
      "current_user_email" => nil,
      "current_user_id" => nil,
      "current_user_is_peek_admin" => nil,
      "current_user_name" => nil,
      "current_user_primary_role" => nil
    }

    {:ok, token, _claims} = generate_and_sign(params, signer)
    token
  end
end
