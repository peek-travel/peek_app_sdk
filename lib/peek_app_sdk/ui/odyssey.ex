defmodule PeekAppSDK.UI.Odyssey do
  @moduledoc """
  A module for rendering Odyssey components.
  """
  use Phoenix.Component

  defdelegate odyssey_activity_picker(assigns), to: PeekAppSDK.UI.Odyssey.OdysseyActivityPicker
  defdelegate odyssey_toggle_button(assigns), to: PeekAppSDK.UI.Odyssey.ToggleButton

  attr(:current_path, :string, required: true)
  attr(:tabs, :list, required: true)
  attr(:info_icon, :boolean, default: false)
  attr(:truncate_text, :boolean, default: false)

  def tabs(assigns) do
    ~H"""
    <div class="my-4 border-b-2 border-gray-300">
      <div class="flex gap-6">
        <.link
          :for={tab <- @tabs}
          patch={tab.path}
          class={[
            "pb-2 text-base font-medium leading-6 relative no-underline",
            tab[:truncate_text] && "truncate",
            @current_path == tab.path && "text-brand -mb-[2px] border-b-2 border-brand",
            @current_path != tab.path && "text-gray-primary"
          ]}
        >
          {tab.name}
          <span :if={tab[:info_icon]} class="ml-0.5">
            <.odyssey_icon name="hero-information-circle" class="h-5 w-5 mb-1 text-warning" />
          </span>
        </.link>
      </div>
    </div>
    """
  end

  @doc """
  Renders a back navigation link.

  ## Examples

      <.back navigate={~p"/posts"}>Back to posts</.back>
  """
  attr(:navigate, :any, required: true)
  slot(:inner_block, required: true)

  def back(assigns) do
    ~H"""
    <.link navigate={@navigate} class="text-xl leading-6 text-zinc-900 hover:text-gray-primary">
      <.odyssey_icon name="hero-arrow-left" class="text-brand h-6 w-6 mr-4" />
      {render_slot(@inner_block)}
    </.link>
    """
  end

  @doc """
  Renders a [Heroicon](https://heroicons.com).

  Heroicons come in three styles – outline, solid, and mini.
  By default, the outline style is used, but solid and mini may
  be applied by using the `-solid` and `-mini` suffix.

  You can customize the size and colors of the icons by setting
  width, height, and background color classes.

  Icons are extracted from the `deps/heroicons` directory and bundled within
  your compiled app.css by the plugin in `assets/vendor/heroicons.js`.

  ## Examples

      <.odyssey_icon name="hero-x-mark" />
      <.odyssey_icon name="hero-arrow-path" class="ml-1 size-3 motion-safe:animate-spin" />
  """
  attr :name, :string, required: true
  attr :class, :string, default: "size-4"

  def odyssey_icon(%{name: "hero-" <> _} = assigns) do
    ~H"""
    <span class={[@name, @class]} />
    """
  end

  def odyssey_divider(assigns) do
    ~H"""
    <div class="border-t border-gray-200 my-4"></div>
    """
  end
end
