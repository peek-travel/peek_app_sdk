defmodule PeekAppSDK.UI.Odyssey.ProductPicker do
  @moduledoc """
  A live component for selecting products with a toggle between "All" and "Specific".
  When "Specific" is selected, displays checkboxes for each product.

  Integrates with forms via a hidden input field and a JS hook.

  When `selected_ids` is not provided, the component automatically extracts IDs
  from the form field's value. It handles lists of structs/maps with an `:id` or
  `"id"` key, as well as `Ecto.Changeset` structs (via `get_change(:id)`).

  ## Examples

      # Auto-extract selected_ids from field value:
      <.odyssey_product_picker
        field={@form[:whitelisted_products]}
        products={@products}
      />

      # Or pass them explicitly:
      <.odyssey_product_picker
        field={@form[:whitelisted_products]}
        products={@products}
        selected_ids={["prod_1", "prod_2"]}
      />
  """

  use Phoenix.LiveComponent
  use Phoenix.Component

  import PeekAppSDK.UI.Odyssey.ToggleButton, only: [odyssey_toggle_button: 1]

  @impl true
  def mount(socket) do
    {:ok, socket}
  end

  @impl true
  def update(assigns, socket) do
    selected_ids = resolve_selected_ids(assigns)
    socket = assign(socket, Map.put(assigns, :selected_ids, selected_ids))

    socket =
      socket
      |> assign_new(:apply_to_mode, fn -> determine_mode(selected_ids) end)

    {:ok, socket}
  end

  defp resolve_selected_ids(%{selected_ids: ids}) when is_list(ids), do: ids
  defp resolve_selected_ids(%{field: field}), do: extract_ids_from_field(field.value)

  @doc """
  Extracts product IDs from a form field value.

  Handles:
  - `nil` or empty list → `[]`
  - list of maps/structs with `:id` or `"id"` key
  - list of `Ecto.Changeset` structs (extracts via `get_change(:id)`)
  """
  def extract_ids_from_field(nil), do: []

  def extract_ids_from_field([_ | _] = items) do
    items
    |> Enum.map(&extract_id/1)
    |> Enum.reject(&is_nil/1)
  end

  def extract_ids_from_field(_), do: []

  defp extract_id(%{__struct__: Ecto.Changeset, changes: %{id: id}}), do: id
  defp extract_id(%{id: id}), do: id
  defp extract_id(%{"id" => id}), do: id
  defp extract_id(_), do: nil

  defp determine_mode([]), do: "all"
  defp determine_mode(_), do: "specific"

  @impl true
  def render(assigns) do
    ~H"""
    <div id={@id} phx-hook="OdysseyProductPicker" data-integration="product-picker">
      <input
        type="hidden"
        name={@field.name}
        value={encode_selected_products(@selected_ids)}
        id={"#{@id}_hidden_field"}
      />

      <div class="space-y-4">
        <.odyssey_toggle_button
          options={[
            %{value: "all", label: @all_label},
            %{value: "specific", label: @specific_label}
          ]}
          selected={@apply_to_mode}
          on_change="toggle_apply_to"
          phx-target={@myself}
          label={@label}
          disabled={@disabled}
        />

        <div
          :if={@apply_to_mode == "specific"}
          class="space-y-2 pl-4 max-h-64 overflow-y-auto"
          phx-update="ignore"
          id={"#{@id}_checkboxes"}
        >
          <div :for={product <- @products} class="flex items-center gap-3">
            <% product_id = product[@id_key] %>
            <input
              type="checkbox"
              id={"#{@id}_product_#{product_id}"}
              checked={product_id in @selected_ids}
              data-product-id={product_id}
              disabled={@disabled}
              class="checkbox checkbox-sm product-picker-checkbox"
            />
            <div
              class="w-3 h-3 rounded-sm flex-shrink-0"
              style={"background-color: #{product[@color_key] || "#888888"}"}
            >
            </div>
            <label for={"#{@id}_product_#{product_id}"} class="text-sm text-gray-700 cursor-pointer">
              {product[@name_key]}
            </label>
          </div>
        </div>
      </div>
    </div>
    """
  end

  @impl true
  def handle_event("toggle_apply_to", %{"value" => mode}, socket) do
    selected_ids =
      case mode do
        "all" -> []
        "specific" -> socket.assigns.selected_ids
      end

    socket =
      socket
      |> assign(:apply_to_mode, mode)
      |> assign(:selected_ids, selected_ids)
      |> push_event("update-product-selection", %{
        field_id: "#{socket.assigns.id}_hidden_field",
        value: encode_selected_products(selected_ids)
      })

    {:noreply, socket}
  end

  defp to_existing_atom(value) when is_atom(value), do: value
  defp to_existing_atom(value) when is_binary(value), do: String.to_existing_atom(value)

  defp encode_selected_products([]), do: ""
  defp encode_selected_products(ids), do: Enum.join(ids, ",")

  @doc """
  Renders a product picker component.

  When `selected_ids` is omitted, the component auto-extracts IDs from the form
  field's value (handling structs, maps, and Ecto changesets).

  ## Examples

      <.odyssey_product_picker
        field={@form[:whitelisted_products]}
        products={@products}
      />

      <.odyssey_product_picker
        field={@form[:whitelisted_products]}
        products={@products}
        selected_ids={["prod_1", "prod_2"]}
      />
  """
  attr :field, :any, required: true, doc: "a Phoenix.HTML.FormField struct"
  attr :id, :string, doc: "component id, defaults to form_field_product_picker"

  attr :products, :list, required: true, doc: "list of product maps"

  attr :selected_ids, :list, doc: "list of pre-selected product IDs (auto-extracted from field value when omitted)"

  attr :id_key, :atom, default: :id, doc: "key to read product ID from each product map"
  attr :name_key, :atom, default: :name, doc: "key to read product name from each product map"
  attr :color_key, :atom, default: :color_hex, doc: "key to read product color hex from each product map"
  attr :all_label, :string, default: "All Products", doc: "label for the 'all' toggle option"
  attr :specific_label, :string, default: "Specific Products", doc: "label for the 'specific' toggle option"
  attr :label, :string, required: false, doc: "label for the toggle button"
  attr :disabled, :boolean, default: false, doc: "whether the picker is disabled"

  def odyssey_product_picker(assigns) do
    assigns =
      assigns
      |> assign_new(:id, fn %{field: field} ->
        "#{field.form.name}_#{field.field}_product_picker"
      end)
      |> assign_new(:label, fn -> nil end)
      |> assign(:id_key, to_existing_atom(assigns[:id_key] || :id))
      |> assign(:name_key, to_existing_atom(assigns[:name_key] || :name))
      |> assign(:color_key, to_existing_atom(assigns[:color_key] || :color_hex))
      |> assign(:module, __MODULE__)

    ~H"""
    <.live_component {assigns} />
    """
  end
end
