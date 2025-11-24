defmodule PeekAppSDK.UI.Odyssey.PrefixInput do
  @moduledoc """
  Input component that renders an input with a configurable prefix (e.g. currency, percentage, or any other prefix).
  """

  use Phoenix.Component

  import PeekAppSDK.UI.Odyssey.Icon

  @doc """
  Renders an input with a prefix (like $ or %).

  ## Examples

      <.odyssey_prefix_input field={@form[:discount]} prefix="$" label="Discount" />
      <.odyssey_prefix_input field={@form[:percentage]} prefix="%" label="Percentage" />
  """
  attr :id, :any, default: nil
  attr :name, :any
  attr :label, :string, default: nil
  attr :value, :any
  attr :prefix, :string, required: true, doc: "the prefix text to display (e.g., '$', '%')"

  attr :type, :string,
    default: "text",
    values: ~w(text number)

  attr :field, Phoenix.HTML.FormField, doc: "a form field struct retrieved from the form, for example: @form[:discount]"

  attr :errors, :list, default: []
  attr :class, :string, default: nil, doc: "additional classes for the input"

  attr :rest, :global, include: ~w(accept autocomplete capture cols disabled form list max maxlength min minlength
         multiple pattern placeholder readonly required rows size step)

  def odyssey_prefix_input(%{field: %Phoenix.HTML.FormField{} = field} = assigns) do
    errors = if Phoenix.Component.used_input?(field), do: field.errors, else: []
    simple_errors = Enum.map(errors, fn {msg, _opts} -> msg end)

    assigns
    |> assign(field: nil, id: assigns.id || field.id)
    |> assign(:errors, simple_errors)
    |> assign_new(:name, fn -> field.name end)
    |> assign_new(:value, fn -> field.value end)
    |> odyssey_prefix_input()
  end

  def odyssey_prefix_input(assigns) do
    ~H"""
    <fieldset class="fieldset mb-2">
      <span :if={@label} class="label block !mb-0">{@label}</span>
      <div class="flex items-center gap-0 w-[200px]">
        <span class="inline-flex items-center justify-center px-3 rounded-l-md border border-r-0 border-neutrals-200 bg-neutrals-50 text-neutrals-300 h-[35px] text-base">
          {@prefix}
        </span>
        <input
          type={@type}
          name={@name}
          id={@id}
          value={Phoenix.HTML.Form.normalize_value(@type, @value)}
          class={[
            "flex-1 rounded-r-md !rounded-l-none border-l-0 input",
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
