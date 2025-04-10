defmodule PeekAppSDK.Demo.DemoLive do
  use Phoenix.LiveView
  import PeekAppSDK.UI.CoreComponents

  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  def render(assigns) do
    ~H"""
    <div class="mx-auto max-w-7xl px-4 py-8">
      <h1 class="text-3xl font-bold mb-8">PeekAppSDK Core Components Demo</h1>

      <section class="mb-12">
        <h2 class="text-2xl font-semibold mb-4" id="modal">Modal</h2>
        <div class="p-6 bg-white rounded-lg shadow-md">
          <.button id="open-modal-btn" phx-click={show_modal("demo-modal")}>
            Open Modal
          </.button>

          <.modal id="demo-modal">
            <h2 class="text-lg font-semibold mb-4">Modal Title</h2>
            <p>This is a modal component from PeekAppSDK.UI.CoreComponents.</p>
          </.modal>
        </div>
      </section>

      <section class="mb-12">
        <h2 class="text-2xl font-semibold mb-4" id="flash">Flash Messages</h2>
        <div class="p-6 bg-white rounded-lg shadow-md space-y-4">
          <.flash kind={:info}>This is an info flash message</.flash>
          <.flash kind={:error}>This is an error flash message</.flash>
        </div>
      </section>

      <section class="mb-12">
        <h2 class="text-2xl font-semibold mb-4" id="buttons">Buttons</h2>
        <div class="p-6 bg-white rounded-lg shadow-md space-y-4">
          <div class="flex flex-wrap gap-4">
            <.button>Primary Button</.button>
            <.button button_type="secondary">Secondary Button</.button>
            <.button button_type="info">Info Button</.button>
            <.button disabled>Disabled Button</.button>
          </div>
        </div>
      </section>

      <section class="mb-12">
        <h2 class="text-2xl font-semibold mb-4" id="table">Table</h2>
        <div class="p-6 bg-white rounded-lg shadow-md">
          <.table id="users-table" rows={[
            %{id: 1, name: "Alice", email: "alice@example.com"},
            %{id: 2, name: "Bob", email: "bob@example.com"},
            %{id: 3, name: "Charlie", email: "charlie@example.com"}
          ]}>
            <:col :let={user} label="ID"><%= user.id %></:col>
            <:col :let={user} label="Name"><%= user.name %></:col>
            <:col :let={user} label="Email"><%= user.email %></:col>
            <:action :let={_user}>
              <.button button_type="info" class="text-sm">View</.button>
            </:action>
          </.table>
        </div>
      </section>

      <section class="mb-12">
        <h2 class="text-2xl font-semibold mb-4" id="icons">Icons</h2>
        <div class="p-6 bg-white rounded-lg shadow-md">
          <div class="flex flex-wrap gap-6">
            <div class="flex flex-col items-center">
              <.icon name="hero-academic-cap" class="w-8 h-8" />
              <span class="text-sm mt-2">academic-cap</span>
            </div>
            <div class="flex flex-col items-center">
              <.icon name="hero-arrow-path" class="w-8 h-8" />
              <span class="text-sm mt-2">arrow-path</span>
            </div>
            <div class="flex flex-col items-center">
              <.icon name="hero-bell" class="w-8 h-8" />
              <span class="text-sm mt-2">bell</span>
            </div>
            <div class="flex flex-col items-center">
              <.icon name="hero-check" class="w-8 h-8" />
              <span class="text-sm mt-2">check</span>
            </div>
            <div class="flex flex-col items-center">
              <.icon name="hero-x-mark-solid" class="w-8 h-8" />
              <span class="text-sm mt-2">x-mark-solid</span>
            </div>
          </div>
        </div>
      </section>

      <section class="mb-12">
        <h2 class="text-2xl font-semibold mb-4" id="loader">Loader</h2>
        <div class="p-6 bg-white rounded-lg shadow-md">
          <div class="flex gap-8">
            <div class="flex flex-col items-center">
              <.loader />
              <span class="text-sm mt-4">Default Loader</span>
            </div>
            <div class="flex flex-col items-center">
              <.loader small />
              <span class="text-sm mt-4">Small Loader</span>
            </div>
          </div>
        </div>
      </section>

      <section class="mb-12">
        <h2 class="text-2xl font-semibold mb-4" id="message">Message</h2>
        <div class="p-6 bg-white rounded-lg shadow-md space-y-4">
          <.message>This is a default message</.message>
          <.message bold>This is a bold message</.message>
          <.message semibold>This is a semibold message</.message>
          <.message background_color="secondary">This is a secondary background message</.message>
          <.message tooltip="This is a tooltip">Message with tooltip</.message>
        </div>
      </section>

      <section class="mb-12">
        <h2 class="text-2xl font-semibold mb-4" id="divider">Divider</h2>
        <div class="p-6 bg-white rounded-lg shadow-md">
          <p class="mb-4">Content above divider</p>
          <.divider />
          <p class="mt-4">Content below divider</p>
        </div>
      </section>
    </div>
    """
  end
end
