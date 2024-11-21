defmodule PeekAppSDK.Client do
  use Tesla

  plug Tesla.Middleware.JSON, engine_opts: [keys: &String.to_atom/1]

  def query_peek_pro(install_id, gql_query, gql_variables \\ %{}) do
    body_params = %{
      "query" => gql_query,
      "variables" => gql_variables
    }

    peek_app_id = Application.fetch_env!(:peek_app_sdk, :peek_app_id)

    url = "#{api_url()}/#{peek_app_id}"

    case request(method: :post, url: url, body: body_params, headers: headers(install_id)) do
      {:ok, %Tesla.Env{status: 200, body: %{data: data}}} ->
        {:ok, data}

      {:ok, %Tesla.Env{status: status}} ->
        {:error, status}
    end
  end

  defp headers(install_id) do
    [
      {"X-Peek-Auth", "Bearer #{PeekAppSDK.Token.new_for_app_installation!(install_id)}"}
    ]
  end

  defp api_url,
    do:
      Application.get_env(
        :peek_app_sdk,
        :peek_api_url,
        "https://noreaga.peek.com/apps/backoffice-gql"
      )
end
