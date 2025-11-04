defmodule PeekAppSDK.UI.Odyssey.ToggleButtonInputComponent do
  @moduledoc """
  A live component for selecting from a set of options using a toggle button group.

  The component renders a group of buttons styled like a toggle button group, where only
  one option can be selected at a time. The selected value is stored in the form field.

  ## Usage

      <.toggle_button_input
        field={@form[:channel]}
        options={["Email", "Text Message"]}
        value_map={%{"Email" => :email, "Text Message" => :sms}}
      />
  """
  use Phoenix.LiveComponent

  import PeekAppSDK.UI.Odyssey, only: [odyssey_toggle_button: 1]

  attr(:field, Phoenix.HTML.FormField, required: true, doc: "the form field to bind to")
  attr(:options, :list, required: true, doc: "list of button options to display")
  attr(:value_map, :map, default: %{}, doc: "optional map to convert display options to field values")
  attr(:id, :string, doc: "component id, defaults to form_field_toggle_button_input")
  attr(:rest, :global)

  def odyssey_toggle_button_input(assigns) do
    assigns =
      assigns
      |> assign_new(:id, fn %{field: field} ->
        "#{field.form.name}_#{field.field}_toggle_button_input"
      end)
      |> assign(module: __MODULE__)

    ~H"""
    <.live_component {assigns} />
    """
  end

  @impl true
  def update(assigns, socket) do
    field_value = assigns.field.value
    value_map = assigns[:value_map] || %{}

    # Find which option corresponds to the current field value
    # Handle both atoms and strings since form values can be either
    selected_option =
      if Enum.empty?(value_map) do
        field_value
      else
        Enum.find(assigns.options, fn opt ->
          mapped_value = Map.get(value_map, opt)
          # Compare both the mapped value and its string representation
          mapped_value == field_value || to_string(mapped_value) == to_string(field_value)
        end)
      end

    # Store the actual field value (what goes in the hidden input)
    actual_value =
      if Enum.empty?(value_map) do
        field_value
      else
        Map.get(value_map, selected_option, field_value)
      end

    socket =
      socket
      |> assign(assigns)
      |> assign(:selected_option, selected_option)
      |> assign(:actual_value, actual_value)
      |> assign(:value_map, value_map)

    {:ok, socket}
  end

  @impl true
  def handle_event("select_option", %{"unit" => option}, socket) do
    value_map = socket.assigns[:value_map] || %{}

    actual_value =
      if Enum.empty?(value_map) do
        option
      else
        Map.get(value_map, option, option)
      end

    socket =
      socket
      |> assign(:selected_option, option)
      |> assign(:actual_value, actual_value)
      |> push_event("trigger-input", %{field_id: socket.assigns.field.id})

    {:noreply, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div id={"toggle_button_#{@field.id}"}>
      <input
        type="hidden"
        id={@field.id}
        name={@field.name}
        value={to_string(@actual_value)}
        phx-change="validate"
      />
      <.odyssey_toggle_button
        options={@options}
        selected={@selected_option}
        on_change="select_option"
        phx-target={@myself}
      />
    </div>
    """
  end
end
