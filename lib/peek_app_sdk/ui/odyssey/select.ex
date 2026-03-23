defmodule PeekAppSDK.UI.Odyssey.Select do
  @moduledoc """
  A generic dropdown LiveComponent for selecting items with search/filter support.

  Each item must have an `id` and `name` field. Color is optional and can be
  specified via the `color_field` assign (defaults to `:color_hex`).

  Supports two modes:
  - **Standalone**: fires an event via `on_select` when an item is selected
  - **Form-integrated**: when a `field` is provided, manages a hidden input for form binding.
    Supports single and multiple selection via the `multiple` attr.

  ## Examples

  Standalone:

      <.odyssey_select
        id="activity-picker"
        items={@activities}
        on_select={:activity_selected}
        title="Select Activity"
      />

  Form-integrated (single select):

      <.odyssey_select
        field={@form[:category_id]}
        items={@categories}
        title="Select Category"
      />

  Form-integrated (multiple select):

      <.odyssey_select
        field={@form[:tag_ids]}
        items={@tags}
        title="Select Tags"
        multiple={true}
      />
  """

  use Phoenix.LiveComponent

  @impl true
  def mount(socket) do
    {:ok,
     socket
     |> assign(:open, false)
     |> assign(:search, "")}
  end

  @impl true
  def update(assigns, socket) do
    socket = assign(socket, assigns)

    socket =
      if socket.assigns[:field] do
        selected_ids = resolve_selected_ids(socket.assigns)
        assign(socket, :selected_ids, selected_ids)
      else
        assign_new(socket, :selected_ids, fn -> [] end)
      end

    {:ok,
     socket
     |> assign_new(:title, fn -> "Select Item" end)
     |> assign_new(:excluded_ids, fn -> [] end)
     |> assign_new(:color_field, fn -> :color_hex end)
     |> assign_new(:context, fn -> nil end)
     |> assign_new(:field, fn -> nil end)
     |> assign_new(:multiple, fn -> false end)
     |> assign_new(:on_select, fn -> nil end)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div
      id={@id}
      class="relative inline-block text-left"
      phx-click-away="close"
      phx-target={@myself}
      phx-hook="OdysseySelect"
    >
      <input
        :if={@field}
        type="hidden"
        id={"#{@id}_hidden_field"}
        name={@field.name}
        value={encode_selected(@selected_ids)}
      />

      <button
        type="button"
        class="inline-flex items-center gap-2 rounded-md border px-3 py-2 text-sm font-medium border-zinc-300 bg-white hover:bg-zinc-50 cursor-pointer"
        phx-click="toggle"
        phx-target={@myself}
        aria-expanded={@open}
      >
        <span>{button_text(@selected_ids, @items, @title, @multiple)}</span>
        <svg class="w-4 h-4 text-zinc-500" viewBox="0 0 20 20" fill="currentColor" aria-hidden="true">
          <path
            fill-rule="evenodd"
            d="M5.23 7.21a.75.75 0 0 1 1.06.02L10 11.168l3.71-3.938a.75.75 0 1 1 1.09 1.028l-4.24 4.5a.75.75 0 0 1-1.09 0l-4.24-4.5a.75.75 0 0 1 .02-1.06z"
            clip-rule="evenodd"
          />
        </svg>
      </button>

      <div
        :if={@open}
        data-dropdown
        class="absolute z-50 w-80 rounded-xl border border-zinc-200 bg-white shadow-lg ring-1 ring-black/10 overflow-hidden"
      >
        <div class="px-3 pt-3">
          <div class="flex items-center gap-2 rounded-md border border-zinc-300 bg-zinc-50 px-3 py-2 text-sm text-zinc-600">
            <svg class="w-4 h-4 opacity-70" viewBox="0 0 20 20" fill="currentColor">
              <path
                fill-rule="evenodd"
                d="M12.9 14.32a8 8 0 1 1 1.414-1.414l3.39 3.39a1 1 0 0 1-1.414 1.414l-3.39-3.39ZM14 8a6 6 0 1 0-12 0 6 6 0 0 0 12 0Z"
                clip-rule="evenodd"
              />
            </svg>
            <input
              type="text"
              class="flex-1 bg-transparent outline-none"
              placeholder="Search"
              value={@search}
              phx-keyup="search"
              phx-target={@myself}
            />
          </div>
        </div>

        <div class="py-2 max-h-[220px] overflow-y-auto">
          <button
            :for={item <- filtered_items(@items, @search, @excluded_ids)}
            type="button"
            class={[
              "text-left flex w-full items-center gap-2 px-3 py-2 text-sm text-zinc-700 hover:bg-zinc-50 cursor-pointer",
              selected?(item, @selected_ids) && "bg-zinc-50 font-medium"
            ]}
            phx-click="select"
            phx-value-id={item.id}
            phx-target={@myself}
          >
            <span
              :if={get_color(item, @color_field)}
              class="inline-block h-2.5 w-2.5 rounded-full mr-2 align-middle"
              aria-hidden="true"
              style={"background-color: #{get_color(item, @color_field)}"}
            />
            <span class="flex-1">{item.name}</span>
            <svg
              :if={selected?(item, @selected_ids)}
              class="w-4 h-4 text-blue-600"
              viewBox="0 0 20 20"
              fill="currentColor"
            >
              <path
                fill-rule="evenodd"
                d="M16.704 4.153a.75.75 0 0 1 .143 1.052l-8 10.5a.75.75 0 0 1-1.127.075l-4.5-4.5a.75.75 0 0 1 1.06-1.06l3.894 3.893 7.48-9.817a.75.75 0 0 1 1.05-.143Z"
                clip-rule="evenodd"
              />
            </svg>
          </button>
        </div>
      </div>
    </div>
    """
  end

  @impl true
  def handle_event("toggle", _, socket) do
    {:noreply, assign(socket, :open, not socket.assigns.open)}
  end

  def handle_event("close", _, socket) do
    {:noreply, socket |> assign(:open, false) |> assign(:search, "")}
  end

  def handle_event("search", %{"value" => value}, socket) do
    {:noreply, assign(socket, :search, value)}
  end

  def handle_event("select", %{"id" => id}, socket) do
    if socket.assigns.field do
      handle_form_select(id, socket)
    else
      handle_standalone_select(id, socket)
    end
  end

  defp handle_standalone_select(id, socket) do
    %{on_select: on_select, context: context} = socket.assigns
    send(self(), {on_select, context, id})
    {:noreply, socket |> assign(:open, false) |> assign(:search, "")}
  end

  defp handle_form_select(id, socket) do
    id_str = to_string(id)

    selected_ids =
      if socket.assigns.multiple do
        if selected_by_id?(id_str, socket.assigns.selected_ids),
          do: Enum.reject(socket.assigns.selected_ids, &(to_string(&1) == id_str)),
          else: Enum.reverse([id_str | Enum.reverse(socket.assigns.selected_ids)])
      else
        [id_str]
      end

    socket =
      socket
      |> assign(:selected_ids, selected_ids)
      |> push_event("trigger-input", %{field_id: "#{socket.assigns.id}_hidden_field"})

    socket =
      if socket.assigns.multiple,
        do: socket,
        else: socket |> assign(:open, false) |> assign(:search, "")

    {:noreply, socket}
  end

  defp get_color(item, field), do: Map.get(item, field)

  defp selected?(item, selected_ids),
    do: selected_by_id?(to_string(item.id), selected_ids)

  defp selected_by_id?(id_str, selected_ids),
    do: id_str in Enum.map(selected_ids, &to_string/1)

  defp button_text([], _items, title, _multiple), do: title
  defp button_text(_ids, _items, title, true), do: title

  defp button_text([id | _], items, title, false) do
    case Enum.find(items, &(to_string(&1.id) == to_string(id))) do
      nil -> title
      item -> item.name
    end
  end

  defp encode_selected([]), do: ""
  defp encode_selected(ids), do: Enum.join(ids, ",")

  defp resolve_selected_ids(%{selected_ids: ids}) when is_list(ids), do: ids

  defp resolve_selected_ids(%{field: field, multiple: true}) do
    case field.value do
      nil -> []
      "" -> []
      ids when is_list(ids) -> Enum.map(ids, &to_string/1)
      ids when is_binary(ids) -> String.split(ids, ",", trim: true)
      id -> [to_string(id)]
    end
  end

  defp resolve_selected_ids(%{field: field}) do
    case field.value do
      nil -> []
      "" -> []
      id -> [to_string(id)]
    end
  end

  defp filtered_items(items, search, excluded_ids) do
    excluded_ids = Enum.map(excluded_ids, &to_string/1)

    items
    |> Enum.reject(&(to_string(&1.id) in excluded_ids))
    |> Enum.filter(&matches_search?(&1, search))
  end

  defp matches_search?(_, ""), do: true

  defp matches_search?(item, search) do
    String.contains?(String.downcase(item.name), String.downcase(search))
  end

  @doc """
  Renders an odyssey_select dropdown component.

  Supports two modes:
  - **Standalone**: fires an event via `on_select` when an item is selected
  - **Form-integrated**: when a `field` is provided, manages a hidden input for form binding

  ## Examples

  Standalone:

      <.odyssey_select
        id="activity-picker"
        items={@activities}
        on_select={:activity_selected}
        title="Select Activity"
      />

  Form-integrated (single select):

      <.odyssey_select
        field={@form[:category_id]}
        items={@categories}
        title="Select Category"
      />

  Form-integrated (multiple select):

      <.odyssey_select
        field={@form[:tag_ids]}
        items={@tags}
        title="Select Tags"
        multiple={true}
      />
  """
  attr :id, :string, required: false
  attr :items, :list, required: true, doc: "list of items with :id and :name fields"
  attr :on_select, :atom, required: false, doc: "message atom sent when item is selected (standalone mode)"
  attr :title, :string, default: "Select Item", doc: "button text"
  attr :excluded_ids, :list, default: [], doc: "list of ids to exclude"
  attr :color_field, :atom, default: :color_hex, doc: "atom for the color field on items"
  attr :context, :any, default: nil, doc: "additional context included in the message"
  attr :label, :string, required: false, doc: "optional label to wrap the select in a fieldset"
  attr :field, Phoenix.HTML.FormField, required: false, doc: "form field for form-integrated mode"
  attr :multiple, :boolean, default: false, doc: "allow multiple selections (form mode only)"
  attr :selected_ids, :list, required: false, doc: "override for pre-selected IDs (form mode only)"

  # Form-integrated mode
  def odyssey_select(%{field: _field} = assigns) do
    assigns =
      assigns
      |> assign_new(:id, fn %{field: field} ->
        "odyssey_select_#{field.form.name}_#{field.field}"
      end)
      |> assign_new(:label, fn -> nil end)
      |> assign(:module, __MODULE__)

    ~H"""
    <%= if @label do %>
      <fieldset class="fieldset mb-2">
        <div>
          <span class="label mb-1 block">{@label}</span>
          <.live_component {assigns} />
        </div>
      </fieldset>
    <% else %>
      <.live_component {assigns} />
    <% end %>
    """
  end

  # Standalone mode
  def odyssey_select(assigns) do
    assigns =
      assigns
      |> assign(:module, __MODULE__)
      |> assign_new(:label, fn -> nil end)

    ~H"""
    <%= if @label do %>
      <fieldset class="fieldset mb-2">
        <div>
          <span class="label mb-1 block">{@label}</span>
          <.live_component {assigns} />
        </div>
      </fieldset>
    <% else %>
      <.live_component {assigns} />
    <% end %>
    """
  end
end
