defmodule PeekAppSDK.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = children(Mix.env())

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: PeekAppSDK.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Start Phoenix endpoint only in dev environment for the demo page
  defp children(:dev) do
    [
      PeekAppSDK.Demo.Endpoint
    ]
  end

  defp children(_), do: []
end
