defmodule PeekAppSDK.Demo.Layouts do
  use Phoenix.Component

  import PeekAppSDK.UI.CoreComponents
  import Phoenix.Controller, only: [get_csrf_token: 0]

  embed_templates("layouts/*")

  def render("root.html", assigns) do
    root(assigns)
  end
end
