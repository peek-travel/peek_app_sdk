defmodule PeekAppSDK.Client do
  require Logger
  use Retry

  alias PeekAppSDK.Config

  @doc """
  Creates a Tesla client with the appropriate middleware configuration.
  """
  def client do
    middleware = [
      {Tesla.Middleware.JSON, engine_opts: [keys: &String.to_atom/1]}
    ]

    Tesla.client(middleware)
  end

  @doc """
  Queries the Peek Pro API.

  ## Examples

  Using the default configuration:

      iex> PeekAppSDK.Client.query_peek_pro("install_id", "query { test }")
      {:ok, %{test: "success"}}

  Using a specific application's configuration:

      iex> PeekAppSDK.Client.query_peek_pro("install_id", "query { test }", %{}, :project_name)
      {:ok, %{test: "success"}}
  """
  @spec query_peek_pro(String.t(), String.t(), map(), atom() | nil) ::
          {:ok, map()} | {:error, any()}
  def query_peek_pro(install_id, gql_query, gql_variables \\ %{}, config_id \\ nil) do
    retry with: 200 |> exponential_backoff() |> randomize() |> cap(2000) |> Stream.take(5), atoms: [:rate_limited] do
      case do_query_peek_pro(install_id, gql_query, gql_variables, config_id) do
        {:error, 429} -> :rate_limited
        result -> result
      end
    after
      result -> result
    else
      error -> error
    end
  end

  defp do_query_peek_pro(install_id, gql_query, gql_variables, config_id) do
    body_params = %{
      "query" => gql_query,
      "variables" => gql_variables
    }

    config = Config.get_config(config_id)
    peek_app_id = config.peek_app_id
    peek_api_key = config.peek_api_key

    operation_name = operation_name(gql_query)

    url = build_backoffice_url(config, peek_app_id, operation_name)

    case Tesla.request(client(),
           method: :post,
           url: url,
           body: body_params,
           headers: headers(install_id, config_id, peek_api_key)
         ) do
      {:ok, %Tesla.Env{status: 200, body: %{errors: [_error | _rest] = errors}}} ->
        {:error, errors}

      {:ok, %Tesla.Env{status: 200, body: %{data: data}}} ->
        {:ok, data}

      {:ok, %Tesla.Env{status: status, body: body}} ->
        Logger.error("Unexpected PeekPro response when hitting #{url} - (#{status}): #{inspect(body)}")
        {:error, status}
    end
  end

  def operation_name(query) do
    regex = ~r/\b(query|mutation|subscription)\s+(\w+)/

    case Regex.run(regex, query) do
      [_, _, operation_name] ->
        Macro.underscore(operation_name)

      _ ->
        raise """
        Please include an operation name in all GraphQL queries/mutations.

        bad:

        query($id: ID!) {
          booking(id: $id) {
            displayId
          }
        }

        good:

        query GetBooking($id: ID!) {
          booking(id: $id) {
            displayId
          }
        }
        """
    end
  end

  defp headers(install_id, config_id, nil) do
    [x_peek_auth_header(install_id, config_id)]
  end

  defp headers(install_id, config_id, peek_api_key) do
    [
      x_peek_auth_header(install_id, config_id),
      {"pk-api-key", peek_api_key}
    ]
  end

  defp x_peek_auth_header(install_id, config_id),
    do: {"X-Peek-Auth", "Bearer #{PeekAppSDK.Token.new_for_app_installation!(install_id, nil, config_id)}"}

  # Migration helper for building backoffice URLs
  defp build_backoffice_url(config, peek_app_id, operation_name) do
    # Check if legacy peek_api_url is configured
    legacy_url = Application.get_env(:peek_app_sdk, :peek_api_url)

    if legacy_url do
      Logger.warning("""
      DEPRECATION WARNING: peek_api_url configuration is deprecated.
      Please update your configuration to use peek_api_base_url instead.

      Current (deprecated): peek_api_url: "#{legacy_url}"
      Recommended: peek_api_base_url: "https://apps.peekapis.com"

      Using legacy URL for backoffice calls: #{legacy_url}
      """)

      # Use the legacy URL directly without appending /backoffice-gql
      "#{String.trim(legacy_url)}/#{peek_app_id}/#{operation_name}"
    else
      # Use the new base URL and append /backoffice-gql
      "#{String.trim(config.peek_api_base_url)}/backoffice-gql/#{peek_app_id}/#{operation_name}"
    end
  end
end
