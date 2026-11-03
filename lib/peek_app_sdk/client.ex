defmodule PeekAppSDK.Client do
  require Logger
  use Retry

  alias PeekAppSDK.Config

  # Response keys that callers read as atoms. Listing them here makes sure the
  # atoms exist once this module is loaded, so `decode_key/1` maps them to atoms.
  @known_keys [:data, :errors, :message, :path, :locations, :extensions]

  @doc """
  Creates a Tesla client with the appropriate middleware configuration.

  Response JSON keys are decoded to existing atoms only. A key with no
  matching atom stays a string.
  """
  def client do
    middleware = [
      {Tesla.Middleware.JSON, engine_opts: [keys: &decode_key/1]}
    ]

    Tesla.client(middleware)
  end

  @doc false
  def known_keys, do: @known_keys

  @doc false
  @spec decode_key(String.t()) :: atom() | String.t()
  def decode_key(key) do
    String.to_existing_atom(key)
  rescue
    ArgumentError -> key
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

      {:ok, %Tesla.Env{status: status}} ->
        Logger.error("Unexpected PeekPro response when hitting #{log_url(url)} - (#{status})")
        {:error, status}
    end
  end

  @doc """
  Queries a platform API and returns the raw response body.

  The `url` must have the same scheme, host and port as the configured
  `peek_api_base_url`. For any other URL no request is sent and
  `{:error, :invalid_host}` is returned.
  """
  @spec query_platform(String.t(), atom(), String.t(), map()) ::
          {:ok, map()} | {:error, list()} | {:error, integer()} | {:error, :invalid_host}
  def query_platform(install_id, method, url, body_params) do
    config = Config.get_config(nil)

    if same_origin?(url, config.peek_api_base_url) do
      do_query_platform(install_id, method, url, body_params, config.peek_api_key)
    else
      Logger.warning("Platform request not sent: #{log_url(url)} is not on the peek_api_base_url host")
      {:error, :invalid_host}
    end
  end

  defp do_query_platform(install_id, method, url, body_params, peek_api_key) do
    case Tesla.request(client(),
           method: method,
           url: url,
           body: body_params,
           headers: headers(install_id, nil, peek_api_key)
         ) do
      {:ok, %Tesla.Env{status: 200, body: %{errors: [_error | _rest] = errors}}} ->
        {:error, errors}

      {:ok, %Tesla.Env{status: 200, body: %{data: data}}} ->
        {:ok, data}

      {:ok, %Tesla.Env{status: status, body: body}} when status in 200..299 ->
        {:ok, body}

      {:ok, %Tesla.Env{status: status}} ->
        Logger.error("Unexpected Platform response when hitting #{log_url(url)} - (#{status})")
        {:error, status}
    end
  end

  # The URL is checked exactly as it is sent; only the configured base URL is trimmed,
  # as `build_backoffice_url/3` does.
  defp same_origin?(url, base_url) do
    url_origin = origin(url)
    url_origin != nil and url_origin == origin(String.trim(base_url))
  end

  defp origin(url) do
    case URI.parse(url) do
      %URI{scheme: scheme, host: host, port: port}
      when scheme in ["http", "https"] and is_binary(host) and host != "" ->
        {scheme, String.downcase(host), port}

      _ ->
        nil
    end
  end

  # The URL for a log line: no query string, fragment or user info.
  defp log_url(url) do
    url
    |> URI.parse()
    |> Map.merge(%{query: nil, fragment: nil, userinfo: nil})
    |> URI.to_string()
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

  def headers(install_id, config_id, nil) do
    [x_peek_auth_header(install_id, config_id)]
  end

  def headers(install_id, config_id, peek_api_key) do
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
