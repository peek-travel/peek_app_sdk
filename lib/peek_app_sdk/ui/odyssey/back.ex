defmodule PeekAppSDK.UI.Odyssey.Back do
  @moduledoc """
  Odyssey back navigation component.
  """
  use Phoenix.Component

  import PeekAppSDK.UI.Odyssey.Icon

  @doc """
  Renders a back navigation link.

  ## Examples

      <.odyssey_back navigate={~p"/posts"}>Back to posts</.odyssey_back>
  """
  attr(:navigate, :any, required: true)
  slot(:inner_block, required: true)

  def odyssey_back(assigns) do
    ~H"""
    <.link navigate={@navigate} class="text-xl leading-6 text-zinc-900 hover:text-gray-primary no-underline">
      <.odyssey_icon name="hero-arrow-left" class="text-brand h-6 w-6 mr-4" />
      {render_slot(@inner_block)}
    </.link>
    """
  end
end
