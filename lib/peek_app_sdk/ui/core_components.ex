defmodule PeekAppSDK.UI.CoreComponents do
  @moduledoc """
  Provides core UI components.

  At first glance, this module may seem daunting, but its goal is to provide
  core building blocks for your application, such as modals, tables, and
  forms. The components consist mostly of markup and are well-documented
  with doc strings and declarative assigns. You may customize and style
  them in any way you want, based on your application growth and needs.

  The default components use Tailwind CSS, a utility-first CSS framework.
  See the [Tailwind CSS documentation](https://tailwindcss.com) to learn
  how to customize them or feel free to swap in another framework altogether.

  Icons are provided by [heroicons](https://heroicons.com). See `icon/1` for usage.
  """
  use Phoenix.Component
  use Gettext, backend: PeekAppSDK.UI.Gettext

  alias Phoenix.LiveView.JS

  @doc """
  Renders a modal.

  ## Examples

      <.modal id="confirm-modal">
        This is a modal.
      </.modal>

  JS commands may be passed to the `:on_cancel` to configure
  the closing/cancel event, for example:

      <.modal id="confirm" on_cancel={JS.navigate(~p"/posts")}>
        This is another modal.
      </.modal>

  """
  attr(:id, :string, required: true)
  attr(:show, :boolean, default: false)
  attr(:on_cancel, JS, default: %JS{})
  attr(:full_width, :boolean, default: true)

  slot(:inner_block, required: true)

  def modal(assigns) do
    ~H"""
    <div
      id={@id}
      phx-mounted={@show && show_modal(@id)}
      phx-remove={hide_modal(@id)}
      data-cancel={JS.exec(@on_cancel, "phx-remove")}
      class="relative z-50 hidden"
    >
      <div :if={!@full_width} id={"#{@id}-bg"} class="bg-gray-900/50 fixed inset-0 transition-opacity" aria-hidden="true" />
      <div
        class={["fixed inset-0 overflow-y-auto", @full_width && "top-14"]}
        aria-labelledby={"#{@id}-title"}
        aria-describedby={"#{@id}-description"}
        role="dialog"
        aria-modal="true"
        tabindex="0"
      >
        <div class={["flex items-center justify-center", if(@full_width, do: "min-h-screen", else: "min-h-full")]}>
          <div class={["w-full", if(@full_width, do: "h-screen", else: "max-w-3xl p-4 sm:p-6 lg:py-8")]}>
            <.focus_wrap
              id={"#{@id}-container"}
              phx-window-keydown={JS.exec("data-cancel", to: "##{@id}")}
              phx-key="escape"
              phx-click-away={JS.exec("data-cancel", to: "##{@id}")}
              class={[
                "shadow-zinc-800/10 ring-zinc-800/10 relative hidden bg-white transition",
                if(@full_width, do: "py-2.5 px-4", else: "rounded-xl p-10 shadow-lg ring-1 transition")
              ]}
            >
              <div class={["absolute", if(@full_width, do: "top-0 left-0", else: "top-6 right-5")]}>
                <button
                  phx-click={JS.exec("data-cancel", to: "##{@id}")}
                  type="button"
                  class={["flex-none p-3", if(!@full_width, do: "-m-3")]}
                  aria-label={gettext("close")}
                >
                  <.icon name={if(@full_width, do: "hero-arrow-left", else: "hero-x-mark-solid")} class="h-6 w-6 text-brand" />
                </button>
              </div>
              <div id={"#{@id}-content"}>
                {render_slot(@inner_block)}
              </div>
            </.focus_wrap>
          </div>
        </div>
      </div>
    </div>
    """
  end

  @doc """
  Renders flash notices.

  ## Examples

      <.flash kind={:info} flash={@flash} />
      <.flash kind={:info} phx-mounted={show("#flash")}>Welcome Back!</.flash>
  """
  attr(:id, :string, doc: "the optional id of flash container")
  attr(:flash, :map, default: %{}, doc: "the map of flash messages to display")
  attr(:title, :string, default: nil)
  attr(:kind, :atom, values: [:info, :error], doc: "used for styling and flash lookup")
  attr(:rest, :global, doc: "the arbitrary HTML attributes to add to the flash container")
  attr(:subtext, :string, default: nil)

  slot(:inner_block, doc: "the optional inner block that renders the flash message")

  def flash(assigns) do
    assigns =
      assigns
      |> assign_new(:id, fn -> "flash-#{assigns.kind}" end)
      |> assign(:color, flash_kind(assigns.kind))
      |> assign(:subtext, Phoenix.Flash.get(assigns.flash, :subtext))

    ~H"""
    <div
      :if={msg = render_slot(@inner_block) || Phoenix.Flash.get(@flash, @kind)}
      id={@id}
      class="fixed top-2 inset-x-2 sm:right-2 sm:left-auto sm:w-96 z-50 bg-white shadow-lg"
      {@rest}
    >
      <.alert color={@color}>
        <%= if @title do %>
          {@title}
        <% end %>
        <:subtitle :if={msg}>{msg}</:subtitle>
        <:subtext :if={@subtext}>{@subtext}</:subtext>
      </.alert>

      <button
        type="button"
        class="group absolute top-1 right-1 p-2"
        aria-label={gettext("close")}
        phx-click={JS.push("lv:clear-flash", value: %{key: @kind}) |> hide("##{@id}")}
      >
        <.icon name="hero-x-mark-solid" class="h-5 w-5 opacity-40 group-hover:opacity-70" />
      </button>
    </div>
    """
  end

  defp flash_kind(:info), do: "success"
  defp flash_kind(:error), do: "danger"

  @doc """
  Shows the flash group with standard titles and content.

  ## Examples

      <.flash_group flash={@flash} />
  """
  attr(:flash, :map, required: true, doc: "the map of flash messages")
  attr(:id, :string, default: "flash-group", doc: "the optional id of flash container")

  def flash_group(assigns) do
    ~H"""
    <div id={@id}>
      <.flash kind={:info} title={gettext("Success!")} flash={@flash} />
      <.flash kind={:error} title={gettext("Error!")} flash={@flash} />
      <.flash
        id="server-error"
        kind={:error}
        title={gettext("Something went wrong!")}
        phx-disconnected={show(".phx-server-error #server-error")}
        phx-connected={hide("#server-error")}
        hidden
      >
        {gettext("Hang in there while we get back on track")}
        <.icon name="hero-arrow-path" class="ml-1 h-3 w-3 animate-spin" />
      </.flash>
    </div>
    """
  end

  @doc """
  Renders a simple form.

  ## Examples

      <.simple_form for={@form} phx-change="validate" phx-submit="save">
        <.input field={@form[:email]} label="Email"/>
        <.input field={@form[:username]} label="Username" />
        <:actions>
          <.button>Save</.button>
        </:actions>
      </.simple_form>
  """
  attr(:for, :any, required: true, doc: "the data structure for the form")
  attr(:as, :any, default: nil, doc: "the server side parameter to collect all input under")

  attr(:rest, :global,
    include: ~w(autocomplete name rel action enctype method novalidate target multipart),
    doc: "the arbitrary HTML attributes to apply to the form tag"
  )

  slot(:inner_block, required: true)
  slot(:actions, doc: "the slot for form actions, such as a submit button")

  def simple_form(assigns) do
    ~H"""
    <.form :let={f} for={@for} as={@as} {@rest}>
      <div class="space-y-4 bg-white">
        {render_slot(@inner_block, f)}
        <div :for={action <- @actions} class="mt-2 flex items-center justify-between gap-6">
          {render_slot(action, f)}
        </div>
      </div>
    </.form>
    """
  end

  @doc """
  Renders a button.

  ## Examples

      <.button>Send!</.button>
      <.button phx-click="go" class="ml-2">Send!</.button>
  """
  attr(:type, :string, default: nil)
  attr(:class, :string, default: nil)
  attr(:rest, :global, include: ~w(disabled form name value))
  attr(:button_type, :string, default: "primary", values: ["primary", "secondary", "info"])
  attr(:disabled, :boolean, default: false)
  attr(:id, :string, default: nil)

  slot(:icon)

  slot(:inner_block, required: true)

  def button(assigns) do
    ~H"""
    <button
      type={@type}
      class={[
        "phx-submit-loading:opacity-75 rounded-md py-2 px-3 font-medium text-sm leading-6 whitespace-nowrap",
        if(@disabled, do: "opacity-50 cursor-not-allowed pointer-events-none"),
        button_classes(@button_type),
        @class
      ]}
      disabled={@disabled}
      id={@id}
      {@rest}
    >
      <span :if={@icon} class="h-4 w-4">{render_slot(@icon)}</span>
      <span>{render_slot(@inner_block)}</span>
    </button>
    """
  end

  defp button_classes(button_type) do
    case button_type do
      "primary" ->
        "bg-brand hover:bg-brand-secondary text-white active:text-white/80"

      "secondary" ->
        "bg-background-primary hover:bg-background-secondary text-brand"

      "info" ->
        "bg-white text-gray-primary border border-gray-200 hover:bg-gray-100/20 hover:shadow-md"
    end
  end

  @doc """
  Renders an input with label and error messages.

  A `Phoenix.HTML.FormField` may be passed as argument,
  which is used to retrieve the input name, id, and values.
  Otherwise all attributes may be passed explicitly.

  ## Types

  This function accepts all HTML input types, considering that:

    * You may also set `type="select"` to render a `<select>` tag

    * `type="checkbox"` is used exclusively to render boolean values

    * For live file uploads, see `Phoenix.Component.live_file_input/1`

  See https://developer.mozilla.org/en-US/docs/Web/HTML/Element/input
  for more information. Unsupported types, such as hidden and radio,
  are best written directly in your templates.

  ## Examples

      <.input field={@form[:email]} type="email" />
      <.input name="my-input" errors={["oh no!"]} />
  """
  attr(:id, :any, default: nil)
  attr(:name, :any)
  attr(:label, :string, default: nil)
  attr(:value, :any)
  attr(:tooltip, :string, default: nil, doc: "message to display in a tooltip")
  attr(:postfix, :string, default: nil, doc: "to display after the input")
  attr(:postfix_link, :boolean, default: false, doc: "to display after the input")
  attr(:disabled, :boolean, default: false)
  attr(:top_caret, :boolean, default: false)

  attr(:type, :string,
    default: "text",
    values: ~w(checkbox color date datetime-local email file month number password
               range search select tel text textarea time url week hidden radio)
  )

  attr(:field, Phoenix.HTML.FormField,
    doc: "a form field struct retrieved from the form, for example: @form[:email]"
  )

  attr(:errors, :list, default: [])
  attr(:checked, :boolean, doc: "the checked flag for checkbox inputs")
  attr(:prompt, :string, default: nil, doc: "the prompt for select inputs")
  attr(:options, :list, doc: "the options to pass to Phoenix.HTML.Form.options_for_select/2")
  attr(:multiple, :boolean, default: false, doc: "the multiple flag for select inputs")

  attr(:rest, :global,
    include: ~w(accept autocomplete capture cols disabled form list max maxlength min minlength
                multiple pattern placeholder readonly required rows size step)
  )

  def input(%{field: %Phoenix.HTML.FormField{} = field} = assigns) do
    errors = if Phoenix.Component.used_input?(field), do: field.errors, else: []

    assigns
    |> assign(field: nil, id: assigns.id || field.id)
    |> assign(:errors, Enum.map(errors, &translate_error(&1)))
    |> assign_new(:name, fn -> if assigns.multiple, do: field.name <> "[]", else: field.name end)
    |> assign_new(:value, fn -> field.value end)
    |> input()
  end

  def input(%{type: "checkbox"} = assigns) do
    assigns =
      assign_new(assigns, :checked, fn ->
        Phoenix.HTML.Form.normalize_value("checkbox", assigns[:value])
      end)

    ~H"""
    <div>
      <label class="flex items-center gap-2 text-sm leading-6 text-gray-primary">
        <input type="hidden" name={@name} value="false" disabled={@rest[:disabled]} />
        <input
          type="checkbox"
          id={@id}
          name={@name}
          value="true"
          checked={@checked}
          class="rounded-md border-zinc-300 text-brand focus:bg-white focus:ring-4 focus:ring-focus-shadow focus:border-brand bg-background-primary"
          {@rest}
        />
        {@label}
      </label>
      <.error :for={msg <- @errors}>{msg}</.error>
    </div>
    """
  end

  def input(%{type: "select"} = assigns) do
    ~H"""
    <div>
      <.label for={@id} tooltip={@tooltip} top_caret={@top_caret}>{@label}</.label>
      <select
        id={@id}
        name={@name}
        class="mt-2 block w-full rounded-md border border-gray-300 bg-background-primary shadow-sm focus:bg-white focus:ring-4 focus:ring-focus-shadow focus:border-brand sm:text-sm sm:py-2.5"
        multiple={@multiple}
        {@rest}
      >
        <option :if={@prompt} value="">{@prompt}</option>
        {Phoenix.HTML.Form.options_for_select(@options, @value)}
      </select>
      <.error :for={msg <- @errors}>{msg}</.error>
    </div>
    """
  end

  def input(%{type: "textarea"} = assigns) do
    ~H"""
    <div>
      <.label for={@id} tooltip={@tooltip} top_caret={@top_caret}>{@label}</.label>
      <div class="relative mt-2">
        <textarea
          id={@id}
          name={@name}
          class={[
            "mt-2 block w-full rounded-md text-zinc-900 bg-background-primary focus:bg-white focus:ring-4 focus:ring-focus-shadow focus:border-brand sm:text-sm sm:leading-6 min-h-[6rem]",
            @errors == [] && "border-zinc-300 focus:bg-white focus:ring-4 focus:ring-focus-shadow focus:border-brand",
            @errors != [] && "border-warning focus:border-warning"
          ]}
          {@rest}
        ><%= Phoenix.HTML.Form.normalize_value("textarea", @value) %></textarea>
      </div>
      <.error :for={msg <- @errors}>{msg}</.error>
    </div>
    """
  end

  def input(%{type: "password"} = assigns) do
    ~H"""
    <div>
      <.label for={@id} tooltip={@tooltip} top_caret={@top_caret}>{@label}</.label>
      <div class="relative mt-2">
        <input
          type={@type}
          name={@name}
          id={@id}
          value={Phoenix.HTML.Form.normalize_value(@type, @value)}
          class={[
            "block w-full rounded-md text-zinc-900 bg-background-primary focus:bg-white focus:ring-4 focus:ring-focus-shadow focus:border-brand sm:text-sm sm:leading-6 border px-3 py-2",
            @errors == [] && "border-zinc-300 focus:bg-white focus:ring-4 focus:ring-focus-shadow focus:border-brand",
            @errors != [] && "border-warning focus:border-warning"
          ]}
          {@rest}
        />
        <button
          type="button"
          phx-hook="TogglePassword"
          data-target={@id}
          id={"#{@id}-toggle"}
          class="absolute inset-y-0 right-0 flex items-center px-3 cursor-pointer"
        >
          <.icon name="hero-eye" class="eye h-4 w-4 text-brand" />
          <.icon name="hero-eye-slash" class="eye-slash hidden h-4 w-4 text-brand" />
        </button>
      </div>
      <.error :for={msg <- @errors}>{msg}</.error>
    </div>
    """
  end

  # All other inputs text, datetime-local, url, password, etc. are handled here...
  def input(assigns) do
    ~H"""
    <div>
      <.label for={@id} tooltip={@tooltip} top_caret={@top_caret}>{@label}</.label>
      <div class="relative mt-2">
        <input
          type={@type}
          name={@name}
          id={@id}
          value={Phoenix.HTML.Form.normalize_value(@type, @value)}
          class={[
            "block w-full rounded-md bg-background-primary focus:bg-white focus:ring-4 focus:ring-focus-shadow focus:border-brand sm:text-sm sm:leading-6",
            @disabled && "bg-white text-gray-500 cursor-not-allowed pointer-events-none",
            @errors == [] && "border-zinc-300 focus:bg-white focus:ring-4 focus:ring-focus-shadow focus:border-brand",
            @errors != [] && "border-warning focus:border-warning"
          ]}
          disabled={@disabled}
          {@rest}
        />
        <span
          :if={@postfix}
          phx-hook={if(@postfix_link, do: "CopyOnClick")}
          id={"#{@id}-copy"}
          data-copy-target={@id}
          class={[
            "absolute inset-y-0 right-0 flex items-center text-sm rounded-r border border-zinc-300 px-3",
            @postfix_link && "cursor-pointer bg-white text-brand font-semibold",
            !@postfix_link && "bg-gray-100 text-gray-primary"
          ]}
        >
          {@postfix}
        </span>
      </div>
      <.error :for={msg <- @errors}>{msg}</.error>
    </div>
    """
  end

  @doc """
  Renders a label.
  """
  attr(:for, :string, default: nil)
  slot(:inner_block, required: true)

  attr(:tooltip, :string, default: nil)
  attr(:top_caret, :boolean, default: false)

  def label(assigns) do
    ~H"""
    <label for={@for} class="flex items-center text-sm leading-6 text-gray-primary">
      <span class="block capitalize">{render_slot(@inner_block)}</span>
      <span :if={@tooltip} class="group relative ml-1">
        <.icon name="hero-information-circle" class="h-4 w-4 mb-0.5 text-gray-primary group-hover:text-gray-700" />
        <.tooltip top_caret={@top_caret}>{@tooltip}</.tooltip>
      </span>
    </label>
    """
  end

  @doc """
  Generates a generic error message.
  """
  slot(:inner_block, required: true)

  def error(assigns) do
    ~H"""
    <p class="mt-3 flex gap-1 text-sm leading-6 text-gray-primary">
      <.icon name="hero-exclamation-circle-mini" class="mt-0.5 h-5 w-5 flex-none text-warning" />
      {render_slot(@inner_block)}
    </p>
    """
  end

  @doc """
  Renders a header with title.
  """
  attr(:class, :string, default: nil)
  attr(:backlink, :string, default: nil)
  attr(:show_divider, :boolean, default: true)
  attr(:text_size, :string, default: "large", values: ["small", "medium", "large"])
  attr(:small, :boolean, default: false)
  attr(:medium, :boolean, default: false)

  attr(:full_width, :boolean,
    default: false,
    doc: "whether to pad the header for the back button for full width `modal`"
  )

  slot(:inner_block, required: true)
  slot(:subtitle)
  slot(:actions)

  def header(assigns) do
    ~H"""
    <header>
      <div class="flex items-center gap-4">
        <.back :if={@backlink} navigate={@backlink}></.back>

        <h1 class={["font-medium leading-8 text-zinc-800", header_text_size(@text_size), @full_width && "ml-8"]}>
          {render_slot(@inner_block)}
        </h1>
        <div class="flex-none ml-auto">{render_slot(@actions)}</div>
      </div>

      <div :if={@show_divider} class="py-4">
        <.divider />
      </div>
      <p :if={@subtitle != []} class={["text-sm leading-6 text-gray-primary bg-background-secondary p-2 rounded-md", !@show_divider && "mt-4"]}>
        {render_slot(@subtitle)}
      </p>
    </header>
    """
  end

  defp header_text_size(text_size) do
    case text_size do
      "small" -> "text-base"
      "medium" -> "text-xl"
      "large" -> "text-2xl"
    end
  end

  attr(:background_color, :string,
    default: "transparent",
    values: ["transparent", "primary", "secondary", "gradient"]
  )

  attr(:text_size, :string, default: "medium", values: ["small", "medium", "large"])

  attr(:text_color, :string,
    default: "gray-primary",
    values: ["gray-primary", "dark-gray", "black"]
  )

  attr(:bold, :boolean, default: false)
  attr(:semibold, :boolean, default: false)
  attr(:tooltip, :string, default: nil)
  attr(:top_caret, :boolean, default: false)

  slot(:inner_block, required: true)
  slot(:actions)

  def message(assigns) do
    ~H"""
    <div class="relative">
      <div class={[
        "leading-6",
        @actions != [] && "flex items-center justify-between gap-6",
        @bold && "font-semibold",
        @semibold && "font-medium",
        background_color(@background_color),
        message_text_size(@text_size),
        message_text_color(@text_color)
      ]}>
        <div class={@tooltip && "flex items-center gap-2"}>
          <p>{render_slot(@inner_block)}</p>
          <div :if={@tooltip} class="group relative">
            <.icon name="hero-information-circle" class="h-4 w-4 mb-1 text-gray-primary group-hover:text-gray-700" />
            <.tooltip top_caret={@top_caret}>{@tooltip}</.tooltip>
          </div>
        </div>
        <div class="flex-none">{render_slot(@actions)}</div>
      </div>
    </div>
    """
  end

  defp message_text_color(text_color) do
    case text_color do
      "gray-primary" -> "text-gray-primary"
      "dark-gray" -> "text-gray-800"
      "black" -> "text-black"
    end
  end

  defp message_text_size(text_size) do
    case text_size do
      "small" -> "text-sm"
      "medium" -> "text-base"
      "large" -> "text-lg"
    end
  end

  defp background_color(background_color) do
    case background_color do
      "transparent" -> "bg-transparent"
      "primary" -> "bg-background-primary p-4 rounded-md"
      "secondary" -> "bg-background-secondary p-4 rounded-md"
      "gradient" -> "bg-gradient-to-r from-pale-green to-pale-blue p-4 rounded-md"
    end
  end

  attr(:image_path, :string)

  slot(:inner_block, required: true)
  slot(:actions)

  def top_header(assigns) do
    ~H"""
    <div class="bg-gradient-to-r from-pale-green to-pale-blue py-3 px-4">
      <div class="flex items-center justify-between gap-6 leading-6 text-gray-primary text-xl max-w-[600px] mx-auto sm:px-4">
        <div class="flex items-center gap-4">
          <img :if={@image_path} src={@image_path} class="h-9 w-9" />
          <p class="font-semibold text-xl text-gray-800">{render_slot(@inner_block)}</p>
        </div>
        <div class="flex-none sm:pr-1">{render_slot(@actions)}</div>
      </div>
    </div>
    """
  end

  attr(:image_path, :string)

  def footer(assigns) do
    ~H"""
    <div class="bg-background-secondary p-4 border-t border-gray-200">
      <div class="flex items-center gap-4 max-w-[600px] mx-auto sm:px-2">
        <img :if={@image_path} src={@image_path} class="w-32" />
      </div>
    </div>
    """
  end

  slot(:inner_block, required: true)

  def user_icon(assigns) do
    ~H"""
    <div class="rounded-full bg-brand-teal p-1.5 text-sm text-white">
      {render_slot(@inner_block)}
    </div>
    """
  end

  @doc ~S"""
  Renders a table with generic styling.

  ## Examples

      <.table id="users" rows={@users}>
        <:col :let={user} label="id"><%= user.id %></:col>
        <:col :let={user} label="username"><%= user.username %></:col>
      </.table>
  """
  attr(:id, :string, required: true)
  attr(:rows, :list, required: true)
  attr(:row_id, :any, default: nil, doc: "the function for generating the row id")
  attr(:row_click, :any, default: nil, doc: "the function for handling phx-click on each row")

  attr(:row_item, :any,
    default: &Function.identity/1,
    doc: "the function for mapping each row before calling the :col and :action slots"
  )

  slot :col, required: true do
    attr(:label, :string)
  end

  slot(:action, doc: "the slot for showing user actions in the last table column")

  def table(assigns) do
    assigns =
      with %{rows: %Phoenix.LiveView.LiveStream{}} <- assigns do
        assign(assigns, row_id: assigns.row_id || fn {id, _item} -> id end)
      end

    ~H"""
    <div class="overflow-y-auto sm:overflow-visible">
      <table class="w-[40rem] sm:w-full">
        <thead class="text-sm text-left leading-6 text-zinc-500 bg-background-secondary">
          <tr>
            <th :for={col <- @col} class="p-4 font-medium capitalize whitespace-nowrap">{col[:label]}</th>
            <th :if={@action != []} class="relative p-0 pb-4">
              <span class="sr-only">{gettext("Actions")}</span>
            </th>
          </tr>
        </thead>
        <tbody
          id={@id}
          phx-update={match?(%Phoenix.LiveView.LiveStream{}, @rows) && "stream"}
          class="relative divide-y divide-zinc-100 border-t border-zinc-200 text-sm leading-6 text-gray-primary"
        >
          <tr :for={row <- @rows} id={@row_id && @row_id.(row)} class="group hover:bg-gray-200/50">
            <td
              :for={{col, _i} <- Enum.with_index(@col)}
              phx-click={@row_click && @row_click.(row)}
              class={["relative p-0", @row_click && "hover:cursor-pointer"]}
            >
              <div class="block p-4">
                <span class="absolute -inset-y-px right-0 sm:rounded-l-xl" />
                <span>
                  {render_slot(col, @row_item.(row))}
                </span>
              </div>
            </td>
            <td :if={@action != []} phx-click={@row_click && @row_click.(row)} class={["relative p-0", @row_click && "hover:cursor-pointer"]}>
              <div class="flex h-full w-full items-center justify-end p-4">
                <span class="absolute -inset-y-px left-0 sm:rounded-r-xl" />
                <span :for={action <- @action} class="relative font-semibold leading-6 text-zinc-900 hover:text-gray-primary">
                  {render_slot(action, @row_item.(row))}
                </span>
              </div>
            </td>
          </tr>
        </tbody>
      </table>
    </div>
    """
  end

  attr(:current_path, :string, required: true)
  attr(:tabs, :list, required: true)
  attr(:info_icon, :boolean, default: false)
  attr(:truncate_text, :boolean, default: false)

  def tabs(assigns) do
    ~H"""
    <div class="my-4 border-b-2 border-gray-300">
      <div class="flex gap-6">
        <.link
          :for={tab <- @tabs}
          patch={tab.path}
          class={[
            "pb-2 text-base font-medium leading-6 relative",
            tab[:truncate_text] && "truncate",
            @current_path == tab.path && "text-brand -mb-[2px] border-b-2 border-brand",
            @current_path != tab.path && "text-gray-primary"
          ]}
        >
          {tab.name}
          <span :if={tab[:info_icon]} class="ml-0.5">
            <.icon name="hero-information-circle" class="h-5 w-5 mb-1 text-warning" />
          </span>
        </.link>
      </div>
    </div>
    """
  end

  @doc """
  Renders a data list.

  ## Examples

      <.list>
        <:item title="Title"><%= @post.title %></:item>
        <:item title="Views"><%= @post.views %></:item>
      </.list>
  """
  slot :item, required: true do
    attr(:title, :string, required: true)
  end

  slot :secondary_item, required: false do
    attr(:item, :string, required: true)
  end

  attr(:bold, :boolean, default: false)
  attr(:grid, :boolean, default: false)

  def list(assigns) do
    ~H"""
    <div>
      <dl class={["-my-4", @grid && "grid grid-cols-2"]}>
        <div :for={item <- @item} class="py-4 text-sm leading-6 sm:gap-8">
          <dt class="text-gray-primary">{item.title}</dt>
          <dd class={["text-gray-primary", @bold && "font-semibold"]}>
            {render_slot(item)}
          </dd>

          <div :for={secondary <- @secondary_item} :if={secondary.item == item.title}>
            <dd class="text-gray-primary text-xs">
              {render_slot(secondary)}
            </dd>
          </div>
        </div>
      </dl>
    </div>
    """
  end

  @doc """
  Renders a back navigation link.

  ## Examples

      <.back navigate={~p"/posts"}>Back to posts</.back>
  """
  attr(:navigate, :any, required: true)
  slot(:inner_block, required: true)

  def back(assigns) do
    ~H"""
    <.link navigate={@navigate} class="text-sm font-semibold leading-6 text-zinc-900 hover:text-gray-primary">
      <.icon name="hero-arrow-left" class="text-brand h-6 w-6" />
      {render_slot(@inner_block)}
    </.link>
    """
  end

  @doc """
  Renders a [Heroicon](https://heroicons.com).

  Heroicons come in three styles – outline, solid, and mini.
  By default, the outline style is used, but solid and mini may
  be applied by using the `-solid` and `-mini` suffix.

  You can customize the size and colors of the icons by setting
  width, height, and background color classes.

  Icons are extracted from the `deps/heroicons` directory and bundled within
  your compiled app.css by the plugin in your `assets/tailwind.config.js`.

  ## Examples

      <.icon name="hero-x-mark-solid" />
      <.icon name="hero-arrow-path" class="ml-1 w-3 h-3 animate-spin" />
  """
  attr(:name, :string, required: true)
  attr(:class, :string, default: nil)

  def icon(%{name: "hero-" <> _} = assigns) do
    ~H"""
    <span class={[@name, @class]} />
    """
  end

  ## JS Commands

  def show(js \\ %JS{}, selector) do
    JS.show(js,
      to: selector,
      time: 300,
      transition:
        {"transition-all transform ease-out duration-300",
         "opacity-0 translate-y-4 sm:translate-y-0 sm:scale-95",
         "opacity-100 translate-y-0 sm:scale-100"}
    )
  end

  def hide(js \\ %JS{}, selector) do
    JS.hide(js,
      to: selector,
      time: 200,
      transition:
        {"transition-all transform ease-in duration-200",
         "opacity-100 translate-y-0 sm:scale-100",
         "opacity-0 translate-y-4 sm:translate-y-0 sm:scale-95"}
    )
  end

  def show_modal(js \\ %JS{}, id) when is_binary(id) do
    js
    |> JS.show(to: "##{id}")
    |> JS.show(
      to: "##{id}-bg",
      time: 300,
      transition: {"transition-all transform ease-out duration-300", "opacity-0", "opacity-100"}
    )
    |> show("##{id}-container")
    |> JS.add_class("overflow-hidden", to: "body")
    |> JS.focus_first(to: "##{id}-content")
  end

  def hide_modal(js \\ %JS{}, id) do
    js
    |> JS.hide(
      to: "##{id}-bg",
      transition: {"transition-all transform ease-in duration-200", "opacity-100", "opacity-0"}
    )
    |> hide("##{id}-container")
    |> JS.hide(to: "##{id}", transition: {"block", "block", "hidden"})
    |> JS.remove_class("overflow-hidden", to: "body")
    |> JS.pop_focus()
  end

  @doc """
  Translates an error message using gettext.
  """
  def translate_error({msg, opts}) do
    # When using gettext, we typically pass the strings we want
    # to translate as a static argument:
    #
    #     # Translate the number of files with plural rules
    #     dngettext("errors", "1 file", "%{count} files", count)
    #
    # However the error messages in our forms and APIs are generated
    # dynamically, so we need to translate them by calling Gettext
    # with our gettext backend as first argument. Translations are
    # available in the errors.po file (as we use the "errors" domain).
    if count = opts[:count] do
      Gettext.dngettext(PeekAppSDK.UI.Gettext, "errors", msg, msg, count, opts)
    else
      Gettext.dgettext(PeekAppSDK.UI.Gettext, "errors", msg, opts)
    end
  end

  @doc """
  Translates the errors for a field from a keyword list of errors.
  """
  def translate_errors(errors, field) when is_list(errors) do
    for {^field, {msg, opts}} <- errors, do: translate_error({msg, opts})
  end

  def divider(assigns) do
    ~H"""
    <div class="border-t border-gray-200"></div>
    """
  end

  attr(:top_caret, :boolean, default: false)

  slot(:inner_block, required: true)

  def tooltip(assigns) do
    ~H"""
    <div class={[
      "absolute left-1/2 -translate-x-1/2 hidden group-hover:flex flex-col items-center w-max max-w-44 z-50",
      if(@top_caret, do: "top-full mt-2", else: "bottom-4 mb-2")
    ]}>
      <%= if @top_caret do %>
        <div class="w-0 h-0 border-l-[6px] border-l-transparent border-r-[6px] border-r-transparent border-b-[6px] border-b-black"></div>
      <% end %>

      <div class="bg-black text-white text-xs rounded-md p-3 shadow-md">
        {render_slot(@inner_block)}
      </div>

      <%= unless @top_caret do %>
        <div class="w-0 h-0 border-l-[6px] border-l-transparent border-r-[6px] border-r-transparent border-t-[6px] border-t-black"></div>
      <% end %>
    </div>
    """
  end

  attr(:small, :boolean, default: false)

  def loader(assigns) do
    ~H"""
    <svg
      aria-hidden="true"
      class={[
        "block mx-auto text-gray-200 dark:text-gray-400 animate-spin fill-teal-600",
        if(@small, do: "w-5 h-5 lg:w-6 lg:h-6", else: "w-12 h-12")
      ]}
      viewBox="0 0 100 101"
      fill="none"
      xmlns="http://www.w3.org/2000/svg"
      data-integration="loader"
    >
      <path
        d="M100 50.5908C100 78.2051 77.6142 100.591 50 100.591C22.3858 100.591 0 78.2051 0 50.5908C0 22.9766 22.3858 0.59082 50 0.59082C77.6142 0.59082 100 22.9766 100 50.5908ZM9.08144 50.5908C9.08144 73.1895 27.4013 91.5094 50 91.5094C72.5987 91.5094 90.9186 73.1895 90.9186 50.5908C90.9186 27.9921 72.5987 9.67226 50 9.67226C27.4013 9.67226 9.08144 27.9921 9.08144 50.5908Z"
        fill="currentColor"
      />
      <path
        d="M93.9676 39.0409C96.393 38.4038 97.8624 35.9116 97.0079 33.5539C95.2932 28.8227 92.871 24.3692 89.8167 20.348C85.8452 15.1192 80.8826 10.7238 75.2124 7.41289C69.5422 4.10194 63.2754 1.94025 56.7698 1.05124C51.7666 0.367541 46.6976 0.446843 41.7345 1.27873C39.2613 1.69328 37.813 4.19778 38.4501 6.62326C39.0873 9.04874 41.5694 10.4717 44.0505 10.1071C47.8511 9.54855 51.7191 9.52689 55.5402 10.0491C60.8642 10.7766 65.9928 12.5457 70.6331 15.2552C75.2735 17.9648 79.3347 21.5619 82.5849 25.841C84.9175 28.9121 86.7997 32.2913 88.1811 35.8758C89.083 38.2158 91.5421 39.6781 93.9676 39.0409Z"
        fill="currentFill"
      />
    </svg>
    """
  end

  def tag(assigns) do
    ~H"""
    <div class="text-sm rounded-full border border-info px-2 py-1 w-fit text-gray-primary">
      {render_slot(@inner_block)}
    </div>
    """
  end

  attr(:color, :string, default: "success", values: ["success", "warning", "danger", "info"])
  attr(:padded, :boolean, default: false, doc: "whether to pad the alert message for flash X")

  slot(:inner_block, required: true)
  slot(:subtitle)
  slot(:subtext)

  def alert(assigns) do
    ~H"""
    <div class={["leading-8 border rounded-md border-l-[5px] p-4", alert_color(@color)]}>
      <div class={["text-gray-primary", @padded && "pr-4"]}>
        {render_slot(@inner_block)}
      </div>

      <div :if={@subtitle != []} class="text-sm leading-6 text-gray-primary py-2">
        {render_slot(@subtitle)}
      </div>

      <div :if={@subtext != []} class="text-sm leading-6 text-gray-primary py-2 font-semibold">
        {render_slot(@subtext)}
      </div>
    </div>
    """
  end

  defp alert_color(color) do
    case color do
      "success" -> "border-success"
      "warning" -> "border-warning"
      "danger" -> "border-danger"
      "info" -> "border-info"
    end
  end
end
