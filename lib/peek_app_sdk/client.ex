defmodule PeekAppSDK.Client do
  require Logger

  use Tesla

  plug Tesla.Middleware.JSON, engine_opts: [keys: &String.to_atom/1]

  def query_peek_pro(install_id, gql_query, gql_variables \\ %{}) do
    body_params = %{
      "query" => gql_query,
      "variables" => gql_variables
    }

    peek_app_id = Application.fetch_env!(:peek_app_sdk, :peek_app_id)
    operation_name = operation_name(gql_query)
    url = "#{api_url()}/#{peek_app_id}/#{operation_name}"

    case request(method: :post, url: url, body: body_params, headers: headers(install_id)) do
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

  defp headers(install_id) do
    [
      {"X-Peek-Auth", "Bearer #{PeekAppSDK.Token.new_for_app_installation!(install_id)}"},
      {"pk-api-key", Application.fetch_env!(:peek_app_sdk, :peek_app_key)}
    ]
  end

  defp api_url,
    do:
      Application.get_env(
        :peek_app_sdk,
        :peek_api_url,
        "https://apps.peekapis.com/backoffice-gql"
      )
end
