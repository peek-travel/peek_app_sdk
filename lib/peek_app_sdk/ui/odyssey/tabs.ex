defmodule PeekAppSDK.UI.Odyssey.Tabs do
  @moduledoc """
  Odyssey tabs component.
  """
  use Phoenix.Component

  import PeekAppSDK.UI.Odyssey.Icon

  attr(:current_path, :string, required: true)
  attr(:tabs, :list, required: true)
  attr(:info_icon, :boolean, default: false)
  attr(:truncate_text, :boolean, default: false)

  def odyssey_tabs(assigns) do
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
end
