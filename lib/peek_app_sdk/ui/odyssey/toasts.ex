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
        "success" -> "border-success"
        "error" -> "border-danger"
        "warning" -> "border-warning"
        "info" -> "border-info"
        _ -> "border-info"
      end

    assigns = assign(assigns, :border_class, border_class)

    ~H"""
    <div
      id={@id}
      phx-hook="ToastHook"
      class={["toast-peek", @border_class]}
    >
      <div class="toast-peek-content">
        <div class="toast-peek-body">
          <div :if={@title != []} class="toast-peek-header">
            <div class="toast-peek-icon">
              <.toast_icon type={@type} />
            </div>
            <div class="toast-peek-title">
              {render_slot(@title)}
            </div>
          </div>

          <div :if={@text != []} class="toast-peek-text">
            {render_slot(@text)}
          </div>
        </div>
        <div class="toast-peek-close">
          <button
            type="button"
            data-close-toast
            class="toast-peek-close-button"
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
