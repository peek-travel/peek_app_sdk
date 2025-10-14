defmodule PeekAppSDK.UI.Odyssey do
  @moduledoc """
  A module for rendering Odyssey components.
  """
  use Phoenix.Component

  defdelegate odyssey_activity_picker(assigns), to: PeekAppSDK.UI.Odyssey.OdysseyActivityPicker
end
