defmodule Semnox do
  @moduledoc """
  A dummy application for testing purposes.
  """
  use Application

  def start(_type, _args) do
    {:ok, self()}
  end
end
