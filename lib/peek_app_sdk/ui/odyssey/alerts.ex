defmodule PeekAppSDK.UI.Odyssey.Alerts do
  @moduledoc """
  Alert components with customizable types, colors, and optional action links.

  ## Usage

  Basic alert:
  ```heex
  <Alerts.alert type="success">
    <:title>Success!</:title>
    <:message>Your action was completed successfully.</:message>
  </Alerts.alert>
  ```

  Alert with action link:
  ```heex
  <Alerts.alert type="info" action_text="Learn More" action_url="https://example.com">
    <:title>Information</:title>
    <:message>Check out our documentation for more details.</:message>
  </Alerts.alert>
  ```

  ## Types
  - `success` - Green border, success icon
  - `error` - Red border, error icon
  - `warning` - Yellow border, warning icon
  - `info` - Blue border, info icon (default)

  ## Styling
  Uses CSS utility classes defined in `@layer utilities` for consistent styling:
  - `.alert-peek` - Main container with border and background
  - `.alert-peek-content` - Flex layout for icon and content
  - `.alert-peek-icon` - Icon positioning
  - `.alert-peek-body` - Main content area
  - `.alert-peek-title` - Title styling
  - `.alert-peek-message` - Message text styling
  - `.alert-peek-action` - Action link positioning
  """
  use Phoenix.Component

  import PeekAppSDK.UI.Odyssey.Icon

  @doc """
  Renders an alert with different types and colors.

  ## Examples

      <.alert type="info">
        <:title>Information</:title>
        <:message>This is an informational message.</:message>
      </.alert>

      <.alert type="success">
        <:title>Success!</:title>
        <:message>Your action was completed successfully.</:message>
      </.alert>
  """
  attr :type, :string, default: "info", values: ["success", "error", "info", "warning"]
  attr :class, :string, default: nil
  attr :action_text, :string, default: nil, doc: "text for the action button"
  attr :action_url, :string, default: nil, doc: "URL for the action button"

  slot :title, required: true
  slot :message, required: false

  def odyssey_alert(assigns) do
    border_class =
      case assigns.type do
        "success" -> "border-success-300"
        "error" -> "border-danger-300"
        "warning" -> "border-warning-300"
        "info" -> "border-info-300"
        _ -> "border-info-300"
      end

    assigns = assign(assigns, :border_class, border_class)

    ~H"""
    <div class={["max-w-4xl mx-auto mt-8 bg-white rounded-lg px-2 py-3 shadow-sm border-l-4 border", @border_class]}>
      <div class="flex items-start">
        <div class="flex-shrink-0 mt-0.5 mr-3">
          <.alert_type_icon type={@type} />
        </div>
        <div class="flex-1">
          <div :if={@title != []} class="font-medium text-base mb-1 text-neutrals-350">
            {render_slot(@title)}
          </div>
          <div class="text-sm leading-relaxed text-neutrals-300">
            {render_slot(@message)}
          </div>
          <div :if={@action_text && @action_url} class="mt-2 flex justify-end">
            <a
              href={@action_url}
              target="_blank"
              rel="noopener noreferrer"
              class="btn btn-tertiary no-underline"
            >
              {@action_text}
            </a>
          </div>
        </div>
      </div>
    </div>
    """
  end

  defp alert_type_icon(%{type: "success"} = assigns) do
    ~H"""
    <.odyssey_icon name="success" class="w-5 h-5 text-green-500" />
    """
  end

  defp alert_type_icon(%{type: "error"} = assigns) do
    ~H"""
    <.odyssey_icon name="alert" class="w-5 h-5 text-red-500" />
    """
  end

  defp alert_type_icon(%{type: "warning"} = assigns) do
    ~H"""
    <.odyssey_icon name="warning" class="w-5 h-5 text-yellow-500" />
    """
  end

  defp alert_type_icon(%{type: "info"} = assigns) do
    ~H"""
    <.odyssey_icon name="info" class="w-5 h-5 text-blue-500" />
    """
  end

  defp alert_type_icon(assigns), do: alert_type_icon(%{assigns | type: "info"})
end
