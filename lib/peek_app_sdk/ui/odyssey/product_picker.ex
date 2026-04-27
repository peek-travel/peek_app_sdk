defmodule PeekAppSDK.UI.Odyssey.ProductPicker do
  @moduledoc """
  A live component for selecting products with a toggle between "All" and "Specific".

  When "Specific" is selected, displays a searchable list where clicking a row
  toggles selection. Selected state is managed server-side (no JS checkbox hacks).

  Integrates with forms via a hidden input field. The parent form is notified of
  changes via the global `trigger-input` phx event (wired up by `addOdysseyGlobalEvents`).

  Products must conform to `%{id: string, name: string, color: string}` (atom keys).
  Callers are responsible for mapping their data to this shape before passing it in.

  When `selected_ids` is not provided, the component automatically extracts IDs
  from the form field's value. It handles lists of structs/maps with an `:id` or
  `"id"` key, as well as `Ecto.Changeset` structs (via `get_change(:id)`).

  ## Examples

      <.odyssey_product_picker
        field={@form[:whitelisted_products]}
        products={Enum.map(@raw_products, &%{id: &1.id, name: &1.name, color: &1.colorHex})}
      />
  """

  use Phoenix.LiveComponent
  use Phoenix.Component

  import PeekAppSDK.UI.Odyssey.ToggleButton, only: [odyssey_toggle_button: 1]

  @impl true
  def mount(socket) do
    {:ok,
     socket
     |> assign(:search, "")
     |> assign(:filtered_products, [])}
  end

  @impl true
  def update(assigns, socket) do
    selected_ids = resolve_selected_ids(assigns)
    search = Map.get(socket.assigns, :search, "")

    socket =
      socket
      |> assign(assigns)
      |> assign(:selected_ids, selected_ids)
      |> assign(:filtered_products, filter_products(assigns[:products] || [], search))
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

  defp filter_products(products, ""), do: products

  defp filter_products(products, search) do
    query = String.downcase(search)
    Enum.filter(products, &String.contains?(String.downcase(&1.name), query))
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div id={@id} data-integration="product-picker">
      <input
        type="hidden"
        name={@field.name}
        value={encode_selected_products(@selected_ids)}
        id={"#{@id}_hidden_field"}
      />

      <div class="space-y-3">
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

        <div :if={@apply_to_mode == "specific"} class="rounded-xl border border-zinc-200 bg-white shadow-sm overflow-hidden">
          <div class="px-3 pt-3 pb-2 border-b border-zinc-100">
            <div class="flex items-center gap-2 rounded-md border border-zinc-300 bg-zinc-50 px-3 py-2 text-sm text-zinc-600">
              <svg
                class="w-4 h-4 opacity-70 shrink-0"
                viewBox="0 0 20 20"
                fill="currentColor"
                aria-hidden="true"
              >
                <path
                  fill-rule="evenodd"
                  d="M12.9 14.32a8 8 0 1 1 1.414-1.414l3.39 3.39a1 1 0 0 1-1.414 1.414l-3.39-3.39ZM14 8a6 6 0 1 0-12 0 6 6 0 0 0 12 0Z"
                  clip-rule="evenodd"
                />
              </svg>
              <input
                type="text"
                class="flex-1 bg-transparent outline-none text-sm"
                placeholder={@search_placeholder}
                value={@search}
                phx-keyup="search"
                phx-target={@myself}
                disabled={@disabled}
              />
              <span
                :if={length(@selected_ids) > 0}
                class="text-xs font-medium text-blue-600 bg-blue-50 px-2 py-0.5 rounded-full shrink-0"
              >
                {length(@selected_ids)} selected
              </span>
            </div>
          </div>

          <div class="max-h-64 overflow-y-auto py-1">
            <button
              :for={product <- @filtered_products}
              type="button"
              class={[
                "flex w-full items-center gap-3 px-4 py-2.5 text-sm text-left transition-colors",
                product.id in @selected_ids && "bg-blue-50",
                product.id not in @selected_ids && "hover:bg-zinc-50",
                @disabled && "pointer-events-none opacity-60"
              ]}
              phx-click="toggle_product"
              phx-value-id={product.id}
              phx-target={@myself}
            >
              <div
                class="w-3 h-3 rounded-sm shrink-0"
                style={"background-color: #{product.color}"}
              />
              <span class="flex-1 text-zinc-700">{product.name}</span>
              <svg
                :if={product.id in @selected_ids}
                class="w-4 h-4 text-blue-600 shrink-0"
                viewBox="0 0 20 20"
                fill="currentColor"
                aria-hidden="true"
              >
                <path
                  fill-rule="evenodd"
                  d="M16.704 4.153a.75.75 0 0 1 .143 1.052l-8 10.5a.75.75 0 0 1-1.127.075l-4.5-4.5a.75.75 0 0 1 1.06-1.06l3.894 3.893 7.48-9.817a.75.75 0 0 1 1.05-.143Z"
                  clip-rule="evenodd"
                />
              </svg>
            </button>

            <p
              :if={@filtered_products == [] && @search != ""}
              class="px-4 py-6 text-sm text-zinc-400 text-center"
            >
              No products match your search.
            </p>
          </div>
        </div>
      </div>
    </div>
    """
  end

  @impl true
  def handle_event("toggle_apply_to", %{"value" => "all"}, socket) do
    socket =
      socket
      |> assign(:apply_to_mode, "all")
      |> assign(:selected_ids, [])
      |> assign(:search, "")
      |> assign(:filtered_products, socket.assigns.products)
      |> push_event("trigger-input", %{field_id: "#{socket.assigns.id}_hidden_field"})

    {:noreply, socket}
  end

  def handle_event("toggle_apply_to", %{"value" => "specific"}, socket) do
    socket =
      socket
      |> assign(:apply_to_mode, "specific")
      |> assign(:search, "")
      |> assign(:filtered_products, socket.assigns.products)

    {:noreply, socket}
  end

  def handle_event("toggle_product", %{"id" => id}, socket) do
    selected_ids =
      if id in socket.assigns.selected_ids,
        do: Enum.reject(socket.assigns.selected_ids, &(&1 == id)),
        else: [id | socket.assigns.selected_ids] |> Enum.reverse()

    socket =
      socket
      |> assign(:selected_ids, selected_ids)
      |> push_event("trigger-input", %{field_id: "#{socket.assigns.id}_hidden_field"})

    {:noreply, socket}
  end

  def handle_event("search", %{"value" => value}, socket) do
    socket =
      socket
      |> assign(:search, value)
      |> assign(:filtered_products, filter_products(socket.assigns.products, value))

    {:noreply, socket}
  end

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
  attr :products, :list, required: true, doc: "list of %{id: string, name: string, color: string} maps"
  attr :selected_ids, :list, doc: "list of pre-selected product IDs (auto-extracted from field value when omitted)"
  attr :all_label, :string, default: "All Products", doc: "label for the 'all' toggle option"
  attr :specific_label, :string, default: "Specific Products", doc: "label for the 'specific' toggle option"
  attr :label, :string, required: false, doc: "label for the toggle button"
  attr :search_placeholder, :string, default: "Search...", doc: "placeholder text for the search input"
  attr :disabled, :boolean, default: false, doc: "whether the picker is disabled"

  def odyssey_product_picker(assigns) do
    assigns =
      assigns
      |> assign_new(:id, fn %{field: field} ->
        "#{field.form.name}_#{field.field}_product_picker"
      end)
      |> assign_new(:label, fn -> nil end)
      |> assign(:module, __MODULE__)

    ~H"""
    <.live_component {assigns} />
    """
  end
end
