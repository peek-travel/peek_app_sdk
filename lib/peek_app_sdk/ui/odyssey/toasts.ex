defmodule PeekAppSDK.UI.Odyssey.Toasts do
  @moduledoc """
  Toast notification components with customizable types and colors.

  ## Usage

  Basic toast:
  ```heex
  <.toast type="success" id="success-toast">
    <:title>Success!</:title>
    <:text>Your action was completed successfully.</:text>
  </.toast>
  ```

  ## Types
  - `success` - Green border, success icon
  - `error` - Red border, error icon
  - `warning` - Yellow border, warning icon
  - `info` - Blue border, info icon (default)

  ## Styling
  Uses Tailwind CSS utility classes applied directly in the template for consistent styling.

  ## JavaScript Hook
  Requires `ToastHook` for auto-dismiss functionality.
  """
  use Phoenix.Component
  import PeekAppSDK.UI.Odyssey.Icons

  @doc """
  Simple toast component with daisyUI styling
  """
  attr :type, :string, default: "info", values: ["success", "error", "info", "warning"]
  attr :id, :string, required: true

  slot :title
  slot :text

  def toast(assigns) do
    border_class =
      case assigns.type do
        "success" -> "border-l-success-300"
        "error" -> "border-l-danger-300"
        "warning" -> "border-l-warning-300"
        "info" -> "border-l-interaction-300"
        _ -> "border-l-interaction-300"
      end

    assigns = assign(assigns, :border_class, border_class)

    ~H"""
    <div
      id={@id}
      phx-hook="ToastHook"
      class={["fixed top-4 right-4 z-50 w-96 bg-white rounded-lg shadow-lg border-l-4 p-4", @border_class]}
    >
      <div class="flex items-start justify-between">
        <div class="flex-1">
          <div :if={@title != []} class="flex items-start space-x-3 mb-1">
            <div class="flex-shrink-0 mt-0.5">
              <.toast_icon type={@type} />
            </div>
            <div class="font-bold text-neutrals-350">
              {render_slot(@title)}
            </div>
          </div>

          <div :if={@text != []} class="text-sm text-neutrals-300 ml-1">
            {render_slot(@text)}
          </div>
        </div>
        <div class="ml-4 flex-shrink-0">
          <button
            type="button"
            data-close-toast
            class="text-neutrals-300 hover:text-gray-600 transition-colors duration-200"
          >
            <.cancel_icon class="w-4 h-4" />
          </button>
        </div>
      </div>
    </div>
    """
  end

  defp toast_icon(%{type: "success"} = assigns) do
    ~H"""
    <.success_icon class="w-5 h-5" />
    """
  end

  defp toast_icon(%{type: "error"} = assigns) do
    ~H"""
    <.alert_icon class="w-5 h-5" />
    """
  end

  defp toast_icon(%{type: "warning"} = assigns) do
    ~H"""
    <.warning_icon class="w-5 h-5" />
    """
  end

  defp toast_icon(%{type: "info"} = assigns) do
    ~H"""
    <.info_icon class="w-5 h-5" />
    """
  end

  defp toast_icon(assigns), do: toast_icon(%{assigns | type: "info"})
end
