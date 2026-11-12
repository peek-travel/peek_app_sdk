defmodule PeekAppSDK.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  alias PeekAppSDK.Plugs.PeekAuth

  @impl true
  def start(_type, _args) do
    # Stop the boot when `:extra_frame_ancestors` is not valid, not on the first request.
    PeekAuth.frame_ancestors()

    children = []

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: PeekAppSDK.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
