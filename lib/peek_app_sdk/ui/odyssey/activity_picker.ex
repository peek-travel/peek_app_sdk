defmodule PeekAppSDK.UI.Odyssey.OdysseyActivityPicker do
  @moduledoc """
  A live component for selecting activities that integrates with forms.
  Uses odyssey-product-picker web component for the UI.

  This component can be used in forms like:

      <.form for={@form} phx-change="change">
        <.odyssey_activity_picker install_id="abc123" field={@form[:activity_id]} />
      </.form>
  """

  use Phoenix.LiveComponent
  use Phoenix.Component

  @impl true
  def mount(socket) do
    {:ok, socket}
  end

  @impl true
  def update(assigns, socket) do
    socket = assign(socket, assigns)

    socket =
      socket
      |> assign(products: load_activities(socket.assigns.install_id))

    {:ok, socket}
  end

  def load_activities(install_id) do
    query = """
      query OdysseyActivityPickerActivities {
        activities {
          name
          id
          colorHex
        }
      }
    """

    case PeekAppSDK.query_peek_pro(install_id, query, %{}) do
      {:ok, %{activities: activities}} ->
        Enum.map(activities, fn activity ->
          %{id: activity.id, name: activity.name, color: activity.colorHex}
        end)
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div phx-hook="OdysseyActivityPicker" id={"#{@id}_hook"}>
      <!-- Hidden input for form value -->
      <input type="hidden" name={@field.name} value={process_ids_for_multi_select(@field.value)} />
      
    <!-- Odyssey product picker will be rendered here -->
      <div>
        <odyssey-product-picker
          id={"#{@id}_picker"}
          phx-update="ignore"
          phx-target={@myself}
          title={@title}
          multiple={if(@multiple, do: "true", else: "false")}
          ids={process_ids_for_multi_select(@field.value)}
          products={Jason.encode!(@products)}
        >
        </odyssey-product-picker>
      </div>
    </div>
    """
  end

  defp process_ids_for_multi_select(ids) do
    ids |> List.wrap() |> Enum.join(",")
  end

  @doc """
  Renders an activity picker component.

  ## Examples
      <.odyssey_activity_picker field={@form[:activity_id]} />
  """
  attr(:field, :any, required: true, doc: "a Phoenix.HTML.FormField struct")
  attr(:id, :string, doc: "component id, defaults to form_field_activity_picker")
  attr(:multiple, :boolean, default: false, doc: "whether to allow multiple selections")
  attr(:install_id, :string, required: true, doc: "the install id for the current partner")
  attr(:title, :string, default: "Activity Picker", doc: "the title for the picker")
  attr(:label, :string, required: false, doc: "optional label to wrap the activity picker in a fieldset")

  def odyssey_activity_picker(assigns) do
    assigns =
      assigns
      |> assign_new(:id, fn %{field: field} ->
        "#{field.form.name}_#{field.field}_activity_picker"
      end)
      |> assign_new(:label, fn -> nil end)
      |> assign(module: __MODULE__)

    ~H"""
    <%= if @label do %>
      <fieldset class="fieldset mb-2">
        <label>
          <span class="label mb-1">{@label}</span>
          <.activity_picker_component {assigns} />
        </label>
      </fieldset>
    <% else %>
      <.activity_picker_component {assigns} />
    <% end %>
    """
  end

  # Private function component for the activity picker to avoid duplication
  defp activity_picker_component(assigns) do
    ~H"""
    <.live_component {assigns} />
    """
  end
end
