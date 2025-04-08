defmodule PeekAppSDK.Client do
  require Logger

  use Tesla

  alias PeekAppSDK.Config

  plug Tesla.Middleware.JSON, engine_opts: [keys: &String.to_atom/1]

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
    body_params = %{
      "query" => gql_query,
      "variables" => gql_variables
    }

    config = Config.get_config(config_id)
    peek_app_id = config.peek_app_id
    peek_app_key = config.peek_app_key

    operation_name = operation_name(gql_query)
    url = "#{config.peek_api_url |> String.trim()}/#{peek_app_id}/#{operation_name}"

    case request(
           method: :post,
           url: url,
           body: body_params,
           headers: headers(install_id, config_id, peek_app_key)
         ) do
      {:ok, %Tesla.Env{status: 200, body: %{data: data}}} ->
        {:ok, data}

      {:ok, %Tesla.Env{status: status, body: body}} ->
        Logger.error("Unexpected PeekPro response (#{status}): #{inspect(body)}")
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

  defp headers(install_id, config_id, peek_app_key) do
    [
      x_peek_auth_header(install_id, config_id),
      {"pk-api-key", peek_app_key}
    ]
  end

  defp x_peek_auth_header(install_id, config_id),
    do:
      {"X-Peek-Auth",
       "Bearer #{PeekAppSDK.Token.new_for_app_installation!(install_id, nil, config_id)}"}
end
