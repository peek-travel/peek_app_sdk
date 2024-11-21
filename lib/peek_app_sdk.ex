defmodule PeekAppSDK do
  @moduledoc """
  PeekAppSDK keeps the contexts that define your domain
  and business logic.

  Contexts are also responsible for managing your data, regardless
  if it comes from the database, an external API or others.
  """

  defdelegate query_peek_pro(install_id, gql_query, gql_variables \\ %{}), to: PeekAppSDK.Client
end
