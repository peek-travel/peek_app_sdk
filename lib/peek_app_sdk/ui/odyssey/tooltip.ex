defmodule PeekAppSDK.UI.Odyssey.Tooltip do
  use Phoenix.Component

  attr(:location, :string, default: "top", values: ~w(top bottom left right))
  attr(:text, :string, required: true)

  slot(:inner_block)

  def odyssey_tooltip(assigns) do
    ~H"""
    <div class="flex items-center gap-2">
      <%= if @inner_block != [] do %>
        <span>{render_slot(@inner_block)}</span>
      <% end %>
      <div class="group relative">
        <span class="hero-information-circle h-4 w-4 mb-1 text-gray-primary group-hover:text-gray-700" />
        <.tooltip location={@location}>{@text}</.tooltip>
      </div>
    </div>
    """
  end

  defp tooltip(assigns) do
    ~H"""
    <div class={[
      "absolute hidden group-hover:flex z-50 w-max max-w-[150px]",
      tooltip_position_class(@location)
    ]}>
      <.caret location={@location} position={:before} />
      <div class="bg-black text-white text-xs rounded-md p-3 shadow-md">
        {render_slot(@inner_block)}
      </div>
      <.caret location={@location} position={:after} />
    </div>
    """
  end

  defp tooltip_position_class("top"), do: "bottom-full mb-2 left-1/2 -translate-x-1/2 flex-col items-center"
  defp tooltip_position_class("bottom"), do: "top-full mt-2 left-1/2 -translate-x-1/2 flex-col items-center"
  defp tooltip_position_class("left"), do: "right-full mr-2 top-1/2 -translate-y-1/2 flex-row items-center"
  defp tooltip_position_class("right"), do: "left-full ml-2 top-1/2 -translate-y-1/2 flex-row items-center"

  defp caret(%{location: "top", position: :after} = assigns) do
    ~H"""
    <div class="w-0 h-0 border-l-[6px] border-l-transparent border-r-[6px] border-r-transparent border-t-[6px] border-t-black"></div>
    """
  end

  defp caret(%{location: "bottom", position: :before} = assigns) do
    ~H"""
    <div class="w-0 h-0 border-l-[6px] border-l-transparent border-r-[6px] border-r-transparent border-b-[6px] border-b-black"></div>
    """
  end

  defp caret(%{location: "left", position: :after} = assigns) do
    ~H"""
    <div class="w-0 h-0 border-t-[6px] border-t-transparent border-b-[6px] border-b-transparent border-l-[6px] border-l-black"></div>
    """
  end

  defp caret(%{location: "right", position: :before} = assigns) do
    ~H"""
    <div class="w-0 h-0 border-t-[6px] border-t-transparent border-b-[6px] border-b-transparent border-r-[6px] border-r-black"></div>
    """
  end

  defp caret(assigns) do
    ~H"""
    """
  end
end
