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
  attr(:disabled, :boolean, default: false, doc: "disable the toggle button")
  attr(:layout, :atom, default: :inline, doc: "layout style: :inline (default) or :stacked (vertical radio-style list)")
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
      |> assign_new(:layout, fn -> :inline end)

    ~H"""
    <%= if @label do %>
      <fieldset class="fieldset mb-2">
        <div>
          <span class="label mb-1 flex items-center gap-1">
            {@label}
            <.odyssey_tooltip :if={@tooltip} text={@tooltip} location={@tooltip_location} />
          </span>
          <.do_odyssey_toggle_button {assigns} />
        </div>
      </fieldset>
    <% else %>
      <div :if={@tooltip && @layout == :inline} class="flex items-center gap-2">
        <.do_odyssey_toggle_button {assigns} />
        <.odyssey_tooltip text={@tooltip} location={@tooltip_location} />
      </div>
      <.do_odyssey_toggle_button :if={is_nil(@tooltip) || @layout == :stacked} {assigns} />
    <% end %>
    """
  end

  # Private function component for the button group to avoid duplication
  defp do_odyssey_toggle_button(%{layout: :stacked} = assigns) do
    assigns = assign_new(assigns, :disabled, fn -> false end)

    ~H"""
    <div class="flex flex-col space-y-4" role="group">
      <button
        :for={option <- @options}
        type="button"
        disabled={@disabled}
        value={to_string(option_value(option))}
        phx-click={
          if @disabled || to_string(@selected) == to_string(option_value(option)),
            do: nil,
            else: @on_change
        }
        phx-target={@phx_target}
        class={[
          "flex items-start gap-4 text-left w-full",
          @disabled && "opacity-50 cursor-not-allowed",
          !@disabled && to_string(@selected) != to_string(option_value(option)) && "cursor-pointer"
        ]}
        {@rest}
      >
        <%= if to_string(@selected) == to_string(option_value(option)) do %>
          <svg class="mt-0.5 shrink-0" width="28" height="28" viewBox="0 0 28 28" fill="none" xmlns="http://www.w3.org/2000/svg">
            <rect x="0.5" y="0.5" width="27" height="27" rx="13.5" fill="#F2F3FA" />
            <rect x="0.5" y="0.5" width="27" height="27" rx="13.5" stroke="#DADCE7" />
            <path
              d="M14.0058 22C12.9047 22 11.8681 21.7917 10.8958 21.375C9.92361 20.9583 9.07292 20.3854 8.34375 19.6562C7.61458 18.9271 7.04167 18.0767 6.625 17.105C6.20833 16.1334 6 15.0952 6 13.9905C6 12.8857 6.20833 11.8507 6.625 10.8854C7.04167 9.92014 7.61458 9.07292 8.34375 8.34375C9.07292 7.61458 9.92332 7.04167 10.895 6.625C11.8666 6.20833 12.9048 6 14.0095 6C15.1143 6 16.1493 6.20833 17.1146 6.625C18.0799 7.04167 18.9271 7.61458 19.6562 8.34375C20.3854 9.07292 20.9583 9.92169 21.375 10.8901C21.7917 11.8585 22 12.8932 22 13.9943C22 15.0953 21.7917 16.1319 21.375 17.1042C20.9583 18.0764 20.3854 18.9271 19.6562 19.6562C18.9271 20.3854 18.0783 20.9583 17.1099 21.375C16.1415 21.7917 15.1068 22 14.0058 22Z"
              fill="#3957EA"
            />
          </svg>
        <% else %>
          <svg class="mt-0.5 shrink-0" width="28" height="28" viewBox="0 0 28 28" fill="none" xmlns="http://www.w3.org/2000/svg">
            <rect x="0.5" y="0.5" width="27" height="27" rx="13.5" fill="#F2F3FA" />
            <rect x="0.5" y="0.5" width="27" height="27" rx="13.5" stroke="#DADCE7" />
          </svg>
        <% end %>
        <div class="flex flex-col ody-neutral-300">
          <span class={[
            "ody-p1",
            to_string(@selected) == to_string(option_value(option)) && "text-gray-900",
            to_string(@selected) != to_string(option_value(option)) && "text-gray-700"
          ]}>
            {option_text(option)}
          </span>
          <span :if={option_description(option)} class="ody-p2 mt-0.5">
            {option_description(option)}
          </span>
        </div>
      </button>
    </div>
    """
  end

  defp do_odyssey_toggle_button(assigns) do
    assigns = assign_new(assigns, :disabled, fn -> false end)

    ~H"""
    <div class="inline-flex rounded-lg" role="group">
      <button
        :for={{option, index} <- Enum.with_index(@options)}
        type="button"
        disabled={@disabled}
        value={to_string(option_value(option))}
        phx-click={
          if @disabled || to_string(@selected) == to_string(option_value(option)),
            do: nil,
            else: @on_change
        }
        phx-target={@phx_target}
        class={[
          "inline-flex items-center gap-2 px-3 py-2 text-sm font-medium transition-colors border border-gray-200",
          index == 0 && "rounded-l-lg",
          index == length(@options) - 1 && "rounded-r-lg",
          index > 0 && "-ml-px",
          @disabled && "opacity-50 cursor-not-allowed",
          !@disabled && to_string(@selected) == to_string(option_value(option)) &&
            "bg-gray-50 text-blue-600 z-10 relative",
          !@disabled && to_string(@selected) != to_string(option_value(option)) &&
            "bg-white text-gray-600 hover:text-gray-900 cursor-pointer"
        ]}
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

  def option_description(%{description: description}), do: description
  def option_description(_option), do: nil
end
