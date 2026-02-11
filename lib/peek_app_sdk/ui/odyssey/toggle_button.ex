defmodule PeekAppSDK.UI.Odyssey.ToggleButton do
  @moduledoc """
  Toggle button component with support for both standalone and form integration.

  Automatically detects form usage when a `field` parameter is provided and delegates
  to the appropriate implementation.

  ## Examples

  Standalone usage:

      <.odyssey_toggle_button
        options={["Minutes", "Hours", "Days"]}
        selected="Minutes"
        on_change="change_time_unit"
      />

      <.odyssey_toggle_button
        options={[
          %{icon: "hero-clock", label: "Minutes"},
          %{icon: "hero-calendar", label: "Hours"},
          %{icon: "hero-calendar-days", label: "Days"}
        ]}
        selected="Minutes"
        on_change="change_time_unit"
      />

  Form integration (automatic when field is provided):

      <.odyssey_toggle_button
        field={@form[:channel]}
        options={[
          %{label: "Email", value: :email},
          %{label: "Text Message", value: :sms}
        ]}
      />
  """
  use Phoenix.Component
  import PeekAppSDK.UI.Odyssey, only: [odyssey_icon: 1, odyssey_tooltip: 1]

  attr(:options, :list,
    required: true,
    doc:
      "list of button options, e.g., [\"Minutes\", \"Hours\", \"Days\"] or [%{icon: \"hero-clock\", label: \"Minutes\", value: :minutes}, %{label: \"Email\", value: :email}]"
  )

  attr(:selected, :string, required: false, doc: "the currently selected option (not needed when using field)")
  attr(:on_change, :string, required: false, doc: "event name to fire on change (not needed when using field)")
  attr(:field, Phoenix.HTML.FormField, required: false, doc: "optional form field for automatic form integration")
  attr(:label, :string, required: false, doc: "optional label to wrap the toggle button in a fieldset")
  attr(:tooltip, :string, required: false, doc: "optional tooltip text to display next to the label")
  attr(:tooltip_location, :string, default: "right", doc: "tooltip position: top, bottom, left, right")
  attr(:phx_target, :any, required: false, doc: "optional phx-target for LiveComponent integration")
  attr(:rest, :global)

  # Form integration mode - when field is provided, delegate to LiveComponent
  def odyssey_toggle_button(%{field: _field} = assigns) do
    assigns =
      assigns
      |> assign_new(:id, fn %{field: field} ->
        "odyssey_toggle_button_#{field.form.name}_#{field.field}"
      end)
      |> assign(:module, PeekAppSDK.UI.Odyssey.ToggleButtonInputComponent)

    ~H"""
    <.live_component {assigns} />
    """
  end

  # Standalone mode - regular component without form integration
  def odyssey_toggle_button(assigns) do
    assigns =
      assigns
      |> assign_new(:phx_target, fn -> nil end)
      |> assign_new(:label, fn -> nil end)
      |> assign_new(:tooltip, fn -> nil end)

    ~H"""
    <%= if @label do %>
      <fieldset class="fieldset mb-2">
        <label>
          <span class="label mb-1">
            <.odyssey_tooltip :if={@tooltip} text={@tooltip} location={@tooltip_location}>{@label}</.odyssey_tooltip>
            <%= if is_nil(@tooltip) do %>
              {@label}
            <% end %>
          </span>
          <.do_odyssey_toggle_button {assigns} />
        </label>
      </fieldset>
    <% else %>
      <.do_odyssey_toggle_button {assigns} />
    <% end %>
    """
  end

  # Private function component for the button group to avoid duplication
  defp do_odyssey_toggle_button(assigns) do
    ~H"""
    <div class="inline-flex rounded-lg" role="group">
      <button
        :for={{option, index} <- Enum.with_index(@options)}
        type="button"
        value={to_string(option_value(option))}
        phx-click={
          if to_string(@selected) == to_string(option_value(option)),
            do: nil,
            else: @on_change
        }
        phx-target={@phx_target}
        class={
          [
            "inline-flex items-center gap-2 px-3 py-2 text-sm font-medium transition-colors border border-gray-200",
            # Rounded corners only on first and last buttons
            index == 0 && "rounded-l-lg",
            index == length(@options) - 1 && "rounded-r-lg",
            # Remove left border on all buttons except the first to avoid double borders
            index > 0 && "-ml-px",
            to_string(@selected) == to_string(option_value(option)) &&
              "bg-gray-50 text-blue-600 z-10 relative",
            to_string(@selected) != to_string(option_value(option)) &&
              "bg-white text-gray-600 hover:text-gray-900 cursor-pointer"
          ]
        }
        {@rest}
      >
        <%= if option_icon(option) do %>
          <.odyssey_icon name={option_icon(option)} class="size-4" />
        <% end %>
        {option_text(option)}
      </button>
    </div>
    """
  end

  # Helper functions for handling option formats
  def option_value(%{value: value}), do: value
  def option_value(%{label: label}), do: label
  def option_value(option) when is_binary(option), do: option

  def option_text(%{label: label}), do: label
  def option_text(option) when is_binary(option), do: option

  def option_icon(%{icon: icon}), do: icon
  def option_icon(_option), do: nil
end
