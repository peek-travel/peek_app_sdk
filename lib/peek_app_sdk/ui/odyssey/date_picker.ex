defmodule PeekAppSDK.UI.Odyssey.DatePicker do
  @moduledoc """
  A date picker input component for selecting dates.

  Provides both standalone usage and convenient integration with
  `Phoenix.HTML.Form` via the `:field` attribute.
  """

  use Phoenix.Component

  import PeekAppSDK.UI.Odyssey.Icon

  @doc """
  Renders a date input with a calendar icon.

  ## Examples

      <.odyssey_date_picker field={@form[:expiration_date]} label="Expiration Date" />
      <.odyssey_date_picker field={@form[:start_date]} label="Start Date" required />
  """
  attr :id, :any, default: nil
  attr :name, :any
  attr :label, :string, default: nil
  attr :value, :any
  attr :errors, :list, default: []
  attr :class, :string, default: nil, doc: "additional classes for the input"

  attr :field, Phoenix.HTML.FormField,
    doc: "a form field struct retrieved from the form, for example: @form[:expiration_date]"

  attr :rest, :global, include: ~w(autocomplete disabled form max min readonly required step)

  def odyssey_date_picker(%{field: %Phoenix.HTML.FormField{} = field} = assigns) do
    errors = if Phoenix.Component.used_input?(field), do: field.errors, else: []
    simple_errors = Enum.map(errors, fn {msg, _opts} -> msg end)

    assigns
    |> assign(field: nil, id: assigns.id || field.id)
    |> assign_new(:errors, fn -> simple_errors end)
    |> assign_new(:name, fn -> field.name end)
    |> assign_new(:value, fn -> field.value end)
    |> odyssey_date_picker()
  end

  def odyssey_date_picker(assigns) do
    ~H"""
    <fieldset class="fieldset mb-2">
      <span :if={@label} class="label !mb-0 block">{@label}</span>
      <div class="relative inline-block w-[200px]">
        <div class="absolute inset-y-0 left-0 flex items-center pl-3 pointer-events-none z-10">
          <.odyssey_icon name="hero-calendar-days" class="size-5 text-neutrals-300" />
        </div>
        <div class="absolute inset-y-0 right-0 flex items-center pr-3 pointer-events-none z-10">
          <.odyssey_icon name="hero-chevron-down" class="size-5 text-interaction-300" />
        </div>
        <input
          type="date"
          name={@name}
          id={@id}
          value={Phoenix.HTML.Form.normalize_value("date", @value)}
          class={[
            "input pl-11 pr-10 w-[200px] cursor-pointer !outline-none",
            "before:absolute before:left-11 before:top-1/2 before:-translate-y-1/2",
            "before:text-neutrals-300 before:pointer-events-none",
            "[&::-webkit-calendar-picker-indicator]:opacity-0",
            "[&::-webkit-calendar-picker-indicator]:absolute",
            "[&::-webkit-calendar-picker-indicator]:inset-0",
            "[&::-webkit-calendar-picker-indicator]:w-full",
            "[&::-webkit-calendar-picker-indicator]:h-full",
            "[&::-webkit-calendar-picker-indicator]:cursor-pointer",
            "[&::-webkit-datetime-edit]:text-neutrals-300",
            "[&::-webkit-datetime-edit]:relative",
            "[&::-webkit-datetime-edit]:left-[32px]",
            "[&:not(:focus):invalid::-webkit-datetime-edit]:opacity-0",
            "[&:not(:focus):invalid]:before:block",
            "[&:focus]:before:hidden",
            "[&:valid]:before:hidden",
            @errors != [] && "input-error",
            @class
          ]}
          {@rest}
        />
      </div>
      <.error :for={msg <- @errors}>{msg}</.error>
    </fieldset>
    """
  end

  defp error(assigns) do
    ~H"""
    <p class="mt-1.5 flex gap-2 items-center text-sm text-error">
      <.odyssey_icon name="hero-exclamation-circle" class="size-5" />
      {render_slot(@inner_block)}
    </p>
    """
  end
end
