defmodule PeekAppSDK.Demo.PageView do
  use Phoenix.View,
    root: "lib/peek_app_sdk/demo/templates",
    namespace: PeekAppSDK.Demo

  # Include shared imports and aliases for views
  import Phoenix.HTML
  use PhoenixHTMLHelpers
end
