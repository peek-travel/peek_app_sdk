defmodule PeekAppSDK.UI.Odyssey.ToggleButtonInputComponent do
  @moduledoc """
  A LiveComponent for toggle buttons with form field integration.

  This component automatically handles form field binding when a field is provided
  to the odyssey_toggle_button component.
  """
  use Phoenix.LiveComponent

  import PeekAppSDK.UI.Odyssey.ToggleButton, only: [odyssey_toggle_button: 1, option_value: 1, option_text: 1]

  @impl true
  def update(assigns, socket) do
    field_value = assigns.field.value
    selected_option_value = find_option_value(assigns.options, field_value)

    socket =
      socket
      |> assign(assigns)
      |> assign(:selected, selected_option_value)

    {:ok, socket}
  end

  @impl true
  def handle_event("odyssey_toggle_button_change", %{"unit" => unit}, socket) do
    selected_value = find_option_value(socket.assigns.options, unit)

    socket =
      socket
      |> assign(:selected, selected_value)
      |> push_event("trigger-input", %{field_id: socket.assigns.field.id})

    {:noreply, socket}
  end

  # Find the option value that matches the given input (field value or clicked unit)
  defp find_option_value(options, input) do
    Enum.find_value(options, fn opt ->
      opt_value = option_value(opt)
      opt_text = option_text(opt)

      cond do
        # Direct match with option value
        opt_value == input -> opt_value
        # String representation match
        to_string(opt_value) == to_string(input) -> opt_value
        # Text label match (for clicked units)
        opt_text == input -> opt_value
        # No match
        true -> nil
      end
    end) || input
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div id={@id}>
      <input
        type="hidden"
        id={@field.id}
        name={@field.name}
        value={to_string(@selected)}
        phx-change="validate"
      />
      <.odyssey_toggle_button
        options={@options}
        selected={@selected}
        on_change="odyssey_toggle_button_change"
        phx_target={@myself}
        {@rest}
      />
    </div>
    """
  end
end
