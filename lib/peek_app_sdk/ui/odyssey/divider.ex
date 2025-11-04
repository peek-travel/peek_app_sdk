defmodule PeekAppSDK.UI.Odyssey.Divider do
  @moduledoc """
  Odyssey divider component.
  """
  use Phoenix.Component

  def odyssey_divider(assigns) do
    ~H"""
    <div class="border-t border-gray-200 my-4"></div>
    """
  end
end
