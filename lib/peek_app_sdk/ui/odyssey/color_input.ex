defmodule PeekAppSDK.UI.Odyssey.ColorInput do
  @moduledoc """
  A color picker input component styled to match Odyssey design system.

  Renders a native color input with a blue chevron indicator matching the
  dropdown styling from core-components.css.
  """

  use Phoenix.Component

  import PeekAppSDK.UI.Odyssey.Icon

  @doc """
  Renders a color input with Odyssey styling.

  ## Examples

      <.odyssey_color_input field={@form[:color]} label="Brand Color" />
      <.odyssey_color_input name="bg_color" value="#3957EA" label="Background" />
  """
  attr :id, :any, default: nil
  attr :name, :any
  attr :label, :string, default: nil
  attr :value, :any, default: "#000000"

  attr :field, Phoenix.HTML.FormField, doc: "a form field struct retrieved from the form, for example: @form[:color]"

  attr :errors, :list, default: []
  attr :class, :string, default: nil, doc: "additional classes for the input"

  attr :rest, :global, include: ~w(disabled form readonly required)

  def odyssey_color_input(%{field: %Phoenix.HTML.FormField{} = field} = assigns) do
    errors = if Phoenix.Component.used_input?(field), do: field.errors, else: []
    simple_errors = Enum.map(errors, fn {msg, _opts} -> msg end)

    assigns
    |> assign(field: nil, id: assigns.id || field.id)
    |> assign(:errors, simple_errors)
    |> assign_new(:name, fn -> field.name end)
    |> assign_new(:value, fn -> field.value || "#000000" end)
    |> odyssey_color_input()
  end

  def odyssey_color_input(assigns) do
    ~H"""
    <fieldset class="fieldset mb-2">
      <label :if={@label} for={@id} class="label !mb-0 block cursor-pointer">{@label}</label>
      <div class="relative inline-block w-fit">
        <input
          type="color"
          name={@name}
          id={@id}
          value={@value}
          class={[
            "h-[35px] w-[60px] rounded-md border border-neutrals-200 bg-neutrals-100 cursor-pointer",
            "hover:border-neutrals-250",
            "focus:outline-none focus:ring-4 focus:ring-neutrals-100 focus:border-neutrals-200",
            @errors != [] && "border-error",
            @class
          ]}
          style="padding: 2px 24px 2px 2px;"
          {@rest}
        />
        <span class="pointer-events-none absolute right-1 top-1/2 -translate-y-1/2">
          <svg
            xmlns="http://www.w3.org/2000/svg"
            fill="none"
            viewBox="0 0 20 20"
            class="size-5"
          >
            <path
              stroke="#3957EA"
              stroke-linecap="round"
              stroke-linejoin="round"
              stroke-width="1.5"
              d="m6 8 4 4 4-4"
            />
          </svg>
        </span>
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
