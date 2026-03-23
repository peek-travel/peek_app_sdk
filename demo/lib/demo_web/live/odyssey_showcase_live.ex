defmodule DemoWeb.OdysseyShowcaseLive do
  @moduledoc """
  A comprehensive showcase of all available Odyssey UI components.

  This LiveView demonstrates how to use each Odyssey component with various
  configurations and options, serving as both a demo and documentation.
  """
  use DemoWeb, :live_view

  @impl true
  def mount(_params, _session, socket) do
    form_data = %{
      "activity_id" => "",
      "channel" => :email,
      "time_unit" => "Minutes",
      "view_mode" => "List",
      "discount" => "",
      "percentage" => "",
      "start_date" => "",
      "expiration_date" => "",
      "whitelisted_products" => "",
      "category_id" => "",
      "tag_ids" => ""
    }

    socket =
      socket
      |> assign(:page_title, "Odyssey Components Showcase")
      |> assign(:current_tab, "components")
      |> assign(:toggle_selection, "Minutes")
      |> assign(:icon_toggle_selection, "Minutes")
      |> assign(:status_selection, "Active")
      |> assign(:size_selection, "Medium")
      |> assign(:channel_selection, :email)
      |> assign(:standalone_select_item, nil)
      |> assign(:form_data, form_data)
      |> assign(:form, to_form(form_data, as: "form"))
      |> assign(:sample_activities, sample_activities())
      |> assign(:sample_products, sample_products())
      |> assign(:sample_categories, sample_categories())
      |> assign(:sample_tags, sample_tags())

    {:ok, socket}
  end

  @impl true
  def handle_event("change_tab", %{"tab" => tab}, socket) do
    {:noreply, assign(socket, :current_tab, tab)}
  end

  @impl true
  def handle_event("change_time_unit", %{"value" => option}, socket) do
    {:noreply, assign(socket, :toggle_selection, option)}
  end

  @impl true
  def handle_event("change_icon_time_unit", %{"value" => option}, socket) do
    {:noreply, assign(socket, :icon_toggle_selection, option)}
  end

  @impl true
  def handle_event("form_change", %{"form" => form_params}, socket) do
    socket =
      socket
      |> assign(:form_data, form_params)
      |> assign(:form, to_form(form_params, as: "form"))

    {:noreply, socket}
  end

  @impl true
  def handle_event("activity_changed", %{"form" => form_params}, socket) do
    socket =
      socket
      |> assign(:form_data, form_params)
      |> assign(:form, to_form(form_params, as: "form"))

    {:noreply, socket}
  end

  @impl true
  def handle_event("change_status", %{"value" => option}, socket) do
    socket = assign(socket, :status_selection, option)
    {:noreply, socket}
  end

  @impl true
  def handle_event("change_size", %{"value" => option}, socket) do
    socket = assign(socket, :size_selection, option)
    {:noreply, socket}
  end

  @impl true
  def handle_event("change_channel", %{"value" => option}, socket) do
    socket = assign(socket, :channel_selection, option)
    {:noreply, socket}
  end

  @impl true
  def handle_event("validate", %{"form" => form_params}, socket) do
    socket =
      socket
      |> assign(:form_data, form_params)
      |> assign(:form, to_form(form_params, as: "form"))

    {:noreply, socket}
  end

  @impl true
  def handle_info({:item_selected, _context, id}, socket) do
    item = Enum.find(socket.assigns.sample_categories, &(to_string(&1.id) == to_string(id)))
    {:noreply, assign(socket, :standalone_select_item, item)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="max-w-6xl mx-auto px-4 py-8">
      <div class="mb-8">
        <h1 class="text-4xl font-bold text-gray-900 mb-4">Odyssey Components Showcase</h1>
        <p class="text-lg text-gray-600">
          A comprehensive demonstration of all available Odyssey UI components with examples and usage patterns.
        </p>
      </div>

    <!-- Navigation Tabs -->
      <div class="my-4 border-b-2 border-gray-300">
        <div class="flex gap-6">
          <button
            phx-click="change_tab"
            phx-value-tab="components"
            class={[
              "pb-2 text-base font-medium leading-6 relative no-underline",
              @current_tab == "components" && "text-blue-600 -mb-[2px] border-b-2 border-blue-600",
              @current_tab != "components" && "text-gray-600 hover:text-gray-900"
            ]}
          >
            Components
          </button>
          <button
            phx-click="change_tab"
            phx-value-tab="icons"
            class={[
              "pb-2 text-base font-medium leading-6 relative no-underline",
              @current_tab == "icons" && "text-blue-600 -mb-[2px] border-b-2 border-blue-600",
              @current_tab != "icons" && "text-gray-600 hover:text-gray-900"
            ]}
          >
            Icons
            <span class="ml-0.5">
              <.odyssey_icon name="hero-information-circle" class="h-5 w-5 mb-1 text-yellow-500" />
            </span>
          </button>
          <button
            phx-click="change_tab"
            phx-value-tab="forms"
            class={[
              "pb-2 text-base font-medium leading-6 relative no-underline",
              @current_tab == "forms" && "text-blue-600 -mb-[2px] border-b-2 border-blue-600",
              @current_tab != "forms" && "text-gray-600 hover:text-gray-900"
            ]}
          >
            Forms
          </button>
        </div>
      </div>

    <!-- Components Section -->
      <div :if={@current_tab == "components"} class="space-y-12">
        <!-- Alerts Section -->
        <section>
          <h2 class="text-2xl font-semibold mb-6">Alert Components</h2>
          <div class="space-y-4">
            <.odyssey_alert type="success">
              <:title>Success Alert</:title>
              <:message>
                This is a success message indicating that an operation completed successfully.
              </:message>
            </.odyssey_alert>
            <.odyssey_alert type="success">
              <:title>Success!</:title>
            </.odyssey_alert>
            <.odyssey_alert type="success" dismissable>
              <:title>Success!</:title>
            </.odyssey_alert>

            <.odyssey_alert type="error">
              <:title>Error Alert</:title>
              <:message>This is an error message indicating that something went wrong.</:message>
            </.odyssey_alert>

            <.odyssey_alert type="warning">
              <:title>Warning Alert</:title>
              <:message>
                This is a warning message to draw attention to important information.
              </:message>
            </.odyssey_alert>

            <.odyssey_alert type="info" action_text="Learn More" action_url="https://example.com">
              <:title>Info Alert with Action</:title>
              <:message>This is an informational message with an optional action button.</:message>
            </.odyssey_alert>

            <.odyssey_alert type="info" dismissable>
              <:title>Dismissable Alert</:title>
              <:message>Click the dismiss button to hide this alert.</:message>
            </.odyssey_alert>

            <.odyssey_alert type="info" dismissable>
              <:title>Alert with Custom Action</:title>
              <:action>
                <button type="button" class="btn btn-primary text-sm">Take Action</button>
              </:action>
            </.odyssey_alert>

            <.odyssey_alert type="success">
              <:title>Content-width Alert</:title>
              <:message>This alert is only as wide as its content.</:message>
            </.odyssey_alert>

            <.odyssey_alert type="warning" full dismissable>
              <:title>Full-width Alert</:title>
              <:message>Use full attr for full-width with actions pushed to the right.</:message>
            </.odyssey_alert>
          </div>
        </section>

        <.odyssey_divider />

    <!-- Toggle Button Section -->
        <section>
          <h2 class="text-2xl font-semibold mb-6">Toggle Button</h2>
          <div class="space-y-4">
            <div>
              <h3 class="text-lg font-medium mb-2">Time Unit Selector</h3>
              <.odyssey_toggle_button
                options={["Minutes", "Hours", "Days"]}
                selected={@toggle_selection}
                on_change="change_time_unit"
              />
              <p class="text-sm text-gray-600 mt-2">Selected: <strong>{@toggle_selection}</strong></p>
            </div>

            <div>
              <h3 class="text-lg font-medium mb-2">Status Options</h3>
              <.odyssey_toggle_button
                options={["Active", "Inactive", "Pending"]}
                selected={@status_selection}
                on_change="change_status"
              />
              <p class="text-sm text-gray-600 mt-2">Selected: <strong>{@status_selection}</strong></p>
            </div>

            <div>
              <h3 class="text-lg font-medium mb-2">Toggle Button with Label</h3>
              <.odyssey_toggle_button
                options={["Small", "Medium", "Large"]}
                selected={@size_selection}
                on_change="change_size"
                label="Size"
              />
              <p class="text-sm text-gray-600 mt-2">Selected: <strong>{@size_selection}</strong></p>
            </div>

            <div>
              <h3 class="text-lg font-medium mb-2">Toggle Buttons with Icons</h3>
              <.odyssey_toggle_button
                options={[
                  %{icon: "hero-clock", label: "Minutes"},
                  %{icon: "hero-calendar", label: "Hours"},
                  %{icon: "hero-calendar-days", label: "Days"}
                ]}
                selected={@icon_toggle_selection}
                on_change="change_icon_time_unit"
              />
              <p class="text-sm text-gray-600 mt-2">
                Selected: <strong>{@icon_toggle_selection}</strong>
              </p>
            </div>

            <div>
              <h3 class="text-lg font-medium mb-2">Toggle Buttons with Value Keys</h3>
              <.odyssey_toggle_button
                options={[
                  %{label: "Email", value: :email},
                  %{label: "Text Message", value: :sms},
                  %{icon: "hero-phone", label: "Phone Call", value: :phone}
                ]}
                selected={@channel_selection}
                on_change="change_channel"
              />
              <p class="text-sm text-gray-600 mt-2">
                Selected value: <strong>{inspect(@channel_selection)}</strong>
              </p>
              <p class="text-sm text-gray-500 mt-1">
                Notice how the value can be different from the display label (atoms vs strings)
              </p>
            </div>

            <div>
              <h3 class="text-lg font-medium mb-2">View Mode Selector (Simple)</h3>
              <.odyssey_toggle_button
                options={["List", "Grid", "Chart"]}
                selected="List"
                on_change="change_view_mode"
              />
            </div>

            <div>
              <h3 class="text-lg font-medium mb-2">Disabled Toggle Button</h3>
              <.odyssey_toggle_button
                options={["Option A", "Option B", "Option C"]}
                selected="Option B"
                on_change="noop"
                disabled
              />
              <p class="text-sm text-gray-600 mt-2">This toggle button is disabled and cannot be interacted with.</p>
            </div>

            <div>
              <h3 class="text-lg font-medium mb-2">Toggle Button with Tooltip (No Label)</h3>
              <.odyssey_toggle_button
                options={["Daily", "Weekly", "Monthly"]}
                selected="Weekly"
                on_change="change_frequency"
                tooltip="Select how often you want to receive reports"
              />
            </div>
          </div>
        </section>

        <.odyssey_divider />

    <!-- Select Dropdown Section -->
        <section>
          <h2 class="text-2xl font-semibold mb-6">Select Dropdown</h2>
          <div class="space-y-4">
            <div>
              <h3 class="text-lg font-medium mb-2">Standalone Select (event-based)</h3>
              <p class="text-gray-600 mb-4">
                Fires an event when an item is selected. No form integration needed.
              </p>
              <.odyssey_select
                id="standalone-category-picker"
                items={@sample_categories}
                on_select={:item_selected}
                title="Pick a Category"
                color_field={:color}
              />
              <p class="text-sm text-gray-600 mt-2">
                Selected: <strong>{if @standalone_select_item, do: @standalone_select_item.name, else: "None"}</strong>
              </p>
            </div>

            <div>
              <h3 class="text-lg font-medium mb-2">Standalone Select with Label</h3>
              <.odyssey_select
                id="labeled-category-picker"
                items={@sample_categories}
                on_select={:item_selected}
                title="Pick a Category"
                color_field={:color}
                label="Category"
              />
            </div>

            <div>
              <h3 class="text-lg font-medium mb-2">Select without Colors</h3>
              <.odyssey_select
                id="no-color-picker"
                items={@sample_tags}
                on_select={:item_selected}
                title="Pick a Tag"
              />
            </div>
          </div>
        </section>

        <.odyssey_divider />

    <!-- Navigation Section -->
        <section>
          <h2 class="text-2xl font-semibold mb-6">Navigation Components</h2>
          <div class="space-y-4">
            <div>
              <h3 class="text-lg font-medium mb-2">Back Navigation</h3>
              <.odyssey_back navigate={~p"/"}>Back to Home</.odyssey_back>
            </div>
          </div>
        </section>

        <.odyssey_divider />

        <section>
          <h2 class="text-2xl font-semibold mb-6">Tooltip Components</h2>
          <div class="space-y-8">
            <div>
              <h3 class="text-lg font-medium mb-4">Top (default)</h3>
              <.odyssey_tooltip text="Tooltip appears above.">
                Hover for info
              </.odyssey_tooltip>
            </div>

            <div>
              <h3 class="text-lg font-medium mb-4">Bottom</h3>
              <.odyssey_tooltip text="Tooltip appears below." location="bottom">
                Hover for info
              </.odyssey_tooltip>
            </div>

            <div>
              <h3 class="text-lg font-medium mb-4">Left</h3>
              <.odyssey_tooltip text="Tooltip appears to the left." location="left">
                Hover for info
              </.odyssey_tooltip>
            </div>

            <div>
              <h3 class="text-lg font-medium mb-4">Right</h3>
              <.odyssey_tooltip text="Tooltip appears to the right." location="right">
                Hover for info
              </.odyssey_tooltip>
            </div>

            <div>
              <h3 class="text-lg font-medium mb-4">Icon Only (no slot content)</h3>
              <.odyssey_tooltip text="Just the info icon, no label." />
            </div>
          </div>
        </section>
      </div>

    <!-- Icons Section -->
      <div :if={@current_tab == "icons"} class="space-y-8">
        <section>
          <h2 class="text-2xl font-semibold mb-6">Heroicons</h2>
          <div class="grid grid-cols-2 md:grid-cols-4 lg:grid-cols-6 gap-4">
            <div class="flex flex-col items-center p-4 border rounded-lg">
              <.odyssey_icon name="hero-home" class="h-8 w-8 mb-2" />
              <span class="text-sm">hero-home</span>
            </div>
            <div class="flex flex-col items-center p-4 border rounded-lg">
              <.odyssey_icon name="hero-user" class="h-8 w-8 mb-2" />
              <span class="text-sm">hero-user</span>
            </div>
            <div class="flex flex-col items-center p-4 border rounded-lg">
              <.odyssey_icon name="hero-cog-6-tooth" class="h-8 w-8 mb-2" />
              <span class="text-sm">hero-cog-6-tooth</span>
            </div>
            <div class="flex flex-col items-center p-4 border rounded-lg">
              <.odyssey_icon name="hero-bell" class="h-8 w-8 mb-2" />
              <span class="text-sm">hero-bell</span>
            </div>
            <div class="flex flex-col items-center p-4 border rounded-lg">
              <.odyssey_icon name="hero-envelope" class="h-8 w-8 mb-2" />
              <span class="text-sm">hero-envelope</span>
            </div>
            <div class="flex flex-col items-center p-4 border rounded-lg">
              <.odyssey_icon name="hero-heart" class="h-8 w-8 mb-2 text-red-500" />
              <span class="text-sm">hero-heart (colored)</span>
            </div>
          </div>
        </section>

        <.odyssey_divider />

        <section>
          <h2 class="text-2xl font-semibold mb-6">Custom SVG Icons</h2>
          <div class="grid grid-cols-2 md:grid-cols-4 lg:grid-cols-5 gap-4">
            <div class="flex flex-col items-center p-4 border rounded-lg">
              <.odyssey_icon name="alert" class="h-8 w-8 mb-2" />
              <span class="text-sm">alert_icon</span>
            </div>
            <div class="flex flex-col items-center p-4 border rounded-lg">
              <.odyssey_icon name="warning" class="h-8 w-8 mb-2" />
              <span class="text-sm">warning_icon</span>
            </div>
            <div class="flex flex-col items-center p-4 border rounded-lg">
              <.odyssey_icon name="info" class="h-8 w-8 mb-2" />
              <span class="text-sm">info_icon</span>
            </div>
            <div class="flex flex-col items-center p-4 border rounded-lg">
              <.odyssey_icon name="success" class="h-8 w-8 mb-2" />
              <span class="text-sm">success_icon</span>
            </div>
            <div class="flex flex-col items-center p-4 border rounded-lg">
              <.odyssey_icon name="cancel" class="h-8 w-8 mb-2" />
              <span class="text-sm">cancel_icon</span>
            </div>
          </div>
        </section>
      </div>

    <!-- Forms Section -->
      <div :if={@current_tab == "forms"} class="space-y-8">
        <section>
          <h2 class="text-2xl font-semibold mb-6">Form Components</h2>

          <div class="space-y-8">
            <div>
              <h3 class="text-lg font-medium mb-4">Toggle Button Input Components</h3>
              <p class="text-gray-600 mb-4">
                Interactive toggle buttons that can be used in forms for selecting between options.
              </p>

              <.form for={@form} phx-change="form_change" class="space-y-6">
                <div>
                  <label class="block text-sm font-medium text-gray-700 mb-2">
                    Communication Channel (with values)
                  </label>
                  <.odyssey_toggle_button
                    field={@form[:channel]}
                    options={[
                      %{label: "Email", value: :email},
                      %{label: "Text Message", value: :sms},
                      %{icon: "hero-megaphone", label: "Push Notification", value: :push}
                    ]}
                  />
                  <p class="text-sm text-gray-500 mt-1">
                    Current value: <strong>{inspect(@form_data["channel"] || :email)}</strong>
                  </p>
                </div>

                <div>
                  <label class="block text-sm font-medium text-gray-700 mb-2">
                    Time Unit (simple strings)
                  </label>
                  <.odyssey_toggle_button
                    field={@form[:time_unit]}
                    options={["Minutes", "Hours", "Days", "Weeks"]}
                  />
                  <p class="text-sm text-gray-500 mt-1">
                    Current value: <strong>{@form_data["time_unit"] || "Minutes"}</strong>
                  </p>
                </div>

                <div>
                  <h3 class="text-lg font-medium mb-2">Toggle with Label and Tooltip</h3>
                  <.odyssey_toggle_button
                    label="Notification Preference"
                    tooltip="Choose how you'd like to receive notifications from us."
                    options={["Email", "SMS", "Push"]}
                    selected="Email"
                    on_change="change_notification"
                  />
                </div>

                <div>
                  <label class="block text-sm font-medium text-gray-700 mb-2">
                    View Mode (with icons)
                  </label>
                  <.odyssey_toggle_button
                    field={@form[:view_mode]}
                    options={[
                      %{icon: "hero-list-bullet", label: "List"},
                      %{icon: "hero-squares-2x2", label: "Grid"},
                      %{icon: "hero-chart-bar", label: "Chart"}
                    ]}
                  />
                  <p class="text-sm text-gray-500 mt-1">
                    Current value: <strong>{@form_data["view_mode"] || "List"}</strong>
                  </p>
                </div>

                <div>
                  <label class="block text-sm font-medium text-gray-700 mb-2">
                    Prefix Inputs (amount and percentage)
                  </label>
                  <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
                    <.odyssey_prefix_input
                      field={@form[:discount]}
                      prefix="$"
                      label="Discount amount"
                      type="number"
                    />
                    <.odyssey_prefix_input
                      field={@form[:percentage]}
                      prefix="%"
                      label="Discount percentage"
                      type="number"
                    />
                  </div>
                  <p class="text-sm text-gray-500 mt-1">
                    Current discount: <strong>{@form_data["discount"] || ""}</strong>,
                    percentage: <strong>{@form_data["percentage"] || ""}</strong>
                  </p>
                </div>

                <div>
                  <label class="block text-sm font-medium text-gray-700 mb-2">
                    Date Pickers (start and expiration)
                  </label>
                  <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
                    <.odyssey_date_picker field={@form[:start_date]} label="Start date" required />
                    <.odyssey_date_picker
                      field={@form[:expiration_date]}
                      label="Expiration date"
                      required
                    />
                  </div>
                  <p class="text-sm text-gray-500 mt-1">
                    Start date: <strong>{@form_data["start_date"] || ""}</strong>,
                    expiration date: <strong>{@form_data["expiration_date"] || ""}</strong>
                  </p>
                </div>

                <div>
                  <label class="block text-sm font-medium text-gray-700 mb-2">
                    Color Input
                  </label>
                  <.odyssey_color_input field={@form[:brand_color]} label="Brand Color" />
                  <p class="text-sm text-gray-500 mt-1">
                    Current color: <strong>{@form_data["brand_color"] || "#000000"}</strong>
                  </p>
                </div>
              </.form>
            </div>

            <.odyssey_divider />

            <div>
              <h3 class="text-lg font-medium mb-4">Product Picker Component</h3>
              <p class="text-gray-600 mb-4">
                Select products with a toggle between "All" and "Specific" modes.
                When "Specific" is selected, checkboxes appear for each product.
              </p>

              <.form for={@form} phx-change="validate" id="product-picker-form">
                <.odyssey_product_picker
                  field={@form[:whitelisted_products]}
                  products={@sample_products}
                  all_label="All Products"
                  specific_label="Specific Products"
                  label="Apply to"
                />
              </.form>
            </div>

            <.odyssey_divider />

            <div>
              <h3 class="text-lg font-medium mb-4">Select Dropdown (Form-Integrated)</h3>
              <p class="text-gray-600 mb-4">
                The same odyssey_select component, but with a form field binding.
                Automatically tracks selected state and syncs with the form.
              </p>

              <.form for={@form} phx-change="validate" id="select-form" class="space-y-6">
                <div>
                  <h4 class="text-base font-medium mb-2">Single Select</h4>
                  <p class="text-gray-500 text-sm mb-2">
                    Selecting an item closes the dropdown and shows the selection in the button.
                  </p>
                  <.odyssey_select
                    field={@form[:category_id]}
                    items={@sample_categories}
                    title="Select Category"
                    color_field={:color}
                    label="Category"
                  />
                  <p class="text-sm text-gray-500 mt-1">
                    Form value: <strong>{@form_data["category_id"] || "(empty)"}</strong>
                  </p>
                </div>

                <div>
                  <h4 class="text-base font-medium mb-2">Multiple Select</h4>
                  <p class="text-gray-500 text-sm mb-2">
                    Clicking items toggles them on/off. Dropdown stays open for further selections.
                  </p>
                  <.odyssey_select
                    field={@form[:tag_ids]}
                    items={@sample_tags}
                    title="Select Tags"
                    multiple={true}
                    label="Tags"
                  />
                  <p class="text-sm text-gray-500 mt-1">
                    Form value: <strong>{@form_data["tag_ids"] || "(empty)"}</strong>
                  </p>
                </div>
              </.form>
            </div>

            <.odyssey_divider />

            <div>
              <h3 class="text-lg font-medium mb-4">Activity Picker Component</h3>
              <p class="text-gray-600 mb-4">
                A sophisticated component for selecting activities with search and filtering capabilities.
              </p>

              <div class="bg-gray-50 p-4 rounded-lg">
                <p class="text-sm text-gray-600 mb-2">
                  <strong>Note:</strong>
                  The Activity Picker component requires a valid install_id and backend integration.
                  In a real application, this would connect to your activity data source.
                </p>
                <div class="bg-white p-3 border rounded">
                  <div class="text-sm text-gray-500">Activity Picker would appear here</div>
                  <div class="text-xs text-gray-400 mt-1">
                    Requires: install_id, field binding, and activity data
                  </div>
                </div>
              </div>
            </div>
          </div>
        </section>
      </div>

    <!-- Code Examples Section -->
      <div class="mt-12 p-6 bg-gray-50 rounded-lg">
        <h2 class="text-xl font-semibold mb-4">Usage Examples</h2>
        <div class="space-y-4 text-sm">
          <div>
            <h3 class="font-medium">Basic Alert:</h3>
            <pre class="bg-white p-3 rounded border overflow-x-auto"><code>&lt;.odyssey_alert type="success"&gt;
              &lt;:title&gt;Success!&lt;/:title&gt;
              &lt;:message&gt;Operation completed successfully.&lt;/:message&gt;
            &lt;/.odyssey_alert&gt;</code></pre>
          </div>

          <div>
            <h3 class="font-medium">Toggle Button:</h3>
            <pre class="bg-white p-3 rounded border overflow-x-auto"><code>&lt;.odyssey_toggle_button
              options={["Option 1", "Option 2", "Option 3"]}
              selected="Option 1"
              on_change="handle_change"
            /&gt;</code></pre>
          </div>

          <div>
            <h3 class="font-medium">Toggle Button with Icons:</h3>
            <pre class="bg-white p-3 rounded border overflow-x-auto"><code>&lt;.odyssey_toggle_button
              options={["List", "Grid"]}
              selected="List"
              on_change="handle_change"
            /&gt;</code></pre>
          </div>

          <div>
            <p>Code examples temporarily disabled for debugging.</p>
          </div>
        </div>
      </div>
    </div>
    """
  end

  defp sample_products do
    [
      %{id: "prod_1", name: "Wine Tasting", color: "#8B5CF6"},
      %{id: "prod_2", name: "Cooking Class", color: "#F59E0B"},
      %{id: "prod_3", name: "City Tour", color: "#10B981"},
      %{id: "prod_4", name: "Sunset Cruise", color: "#3B82F6"}
    ]
  end

  defp sample_categories do
    [
      %{id: "cat_1", name: "Food & Drink", color: "#F59E0B"},
      %{id: "cat_2", name: "Outdoor Adventures", color: "#10B981"},
      %{id: "cat_3", name: "Arts & Culture", color: "#8B5CF6"},
      %{id: "cat_4", name: "Water Sports", color: "#3B82F6"},
      %{id: "cat_5", name: "Nightlife", color: "#EC4899"}
    ]
  end

  defp sample_tags do
    [
      %{id: "tag_1", name: "Family Friendly"},
      %{id: "tag_2", name: "Bestseller"},
      %{id: "tag_3", name: "New"},
      %{id: "tag_4", name: "Seasonal"},
      %{id: "tag_5", name: "Premium"},
      %{id: "tag_6", name: "Group Discount"}
    ]
  end

  defp sample_activities do
    [
      %{
        "id" => "1",
        "name" => "Running",
        "color" => "#FF6B6B",
        "group" => "Cardio"
      },
      %{
        "id" => "2",
        "name" => "Cycling",
        "color" => "#4ECDC4",
        "group" => "Cardio"
      },
      %{
        "id" => "3",
        "name" => "Weight Training",
        "color" => "#45B7D1",
        "group" => "Strength"
      },
      %{
        "id" => "4",
        "name" => "Yoga",
        "color" => "#96CEB4",
        "group" => "Flexibility"
      }
    ]
  end
end
