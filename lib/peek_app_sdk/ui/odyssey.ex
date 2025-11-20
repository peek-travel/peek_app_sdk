defmodule PeekAppSDK.UI.Odyssey do
  @moduledoc """
  A module for rendering Odyssey components.
  """
  use Phoenix.Component

  import LiveSelect

  defdelegate odyssey_activity_picker(assigns), to: PeekAppSDK.UI.Odyssey.OdysseyActivityPicker
  defdelegate odyssey_alert(assigns), to: PeekAppSDK.UI.Odyssey.Alerts
  defdelegate odyssey_back(assigns), to: PeekAppSDK.UI.Odyssey.Back
  defdelegate odyssey_divider(assigns), to: PeekAppSDK.UI.Odyssey.Divider
  defdelegate odyssey_icon(assigns), to: PeekAppSDK.UI.Odyssey.Icon
  defdelegate odyssey_tabs(assigns), to: PeekAppSDK.UI.Odyssey.Tabs
  defdelegate odyssey_toggle_button(assigns), to: PeekAppSDK.UI.Odyssey.ToggleButton
  defdelegate odyssey_prefix_input(assigns), to: PeekAppSDK.UI.Odyssey.PrefixInput
  defdelegate odyssey_date_picker(assigns), to: PeekAppSDK.UI.Odyssey.DatePicker
end
