defmodule PeekAppSDK.Demo.PageHTML do
  use Phoenix.Component

  import PeekAppSDK.UI.CoreComponents

  embed_templates("page_html/*")

  # The home/1 function is automatically defined by embed_templates
  # but we need to explicitly define the render/2 function
  def render(template, assigns)
      when template == :home do
    home(assigns)
  end
end
