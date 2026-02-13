defmodule PeekAppSDK.UI.OdysseyTest do
  use ExUnit.Case
  import Phoenix.LiveViewTest
  import Phoenix.Component

  alias PeekAppSDK.UI.Odyssey

  describe "odyssey_toggle_button component" do
    test "renders all options" do
      html =
        render_component(&Odyssey.odyssey_toggle_button/1, %{
          options: ["Minutes", "Hours", "Days"],
          selected: "Minutes",
          on_change: "change_time_unit"
        })

      assert html =~ "Minutes"
      assert html =~ "Hours"
      assert html =~ "Days"
    end

    test "highlights selected option" do
      html =
        render_component(&Odyssey.odyssey_toggle_button/1, %{
          options: ["Minutes", "Hours", "Days"],
          selected: "Hours",
          on_change: "change_time_unit"
        })

      assert html =~ "bg-gray-50 text-blue-600"
    end

    test "does not attach phx-click for selected option" do
      html =
        render_component(&Odyssey.odyssey_toggle_button/1, %{
          options: ["Minutes", "Hours", "Days"],
          selected: "Hours",
          on_change: "change_time_unit"
        })

      refute html =~ ~r/value="Hours"[^>]*phx-click=/
      assert html =~ ~r/value="Minutes"[^>]*phx-click="change_time_unit"/
    end

    test "shows unselected options with gray styling" do
      html =
        render_component(&Odyssey.odyssey_toggle_button/1, %{
          options: ["Minutes", "Hours", "Days"],
          selected: "Days",
          on_change: "change_time_unit"
        })

      assert html =~ "bg-white text-gray-600 hover:text-gray-900 cursor-pointer"
    end

    test "renders options with icons when maps are provided" do
      html =
        render_component(&Odyssey.odyssey_toggle_button/1, %{
          options: [%{icon: "hero-clock", label: "Minutes"}, %{icon: "hero-calendar", label: "Hours"}],
          selected: "Minutes",
          on_change: "change_time_unit"
        })

      assert html =~ "Minutes"
      assert html =~ "Hours"
      assert html =~ "hero-clock"
      assert html =~ "hero-calendar"
    end

    test "supports value key for different display vs actual values" do
      html =
        render_component(&Odyssey.odyssey_toggle_button/1, %{
          options: [
            %{label: "Email", value: :email},
            %{label: "Text Message", value: :sms},
            %{icon: "hero-phone", label: "Phone Call", value: :phone}
          ],
          selected: :email,
          on_change: "change_channel"
        })

      assert html =~ "Email"
      assert html =~ "Text Message"
      assert html =~ "Phone Call"
      assert html =~ "hero-phone"
      # Should have the selected button highlighted (email)
      # Selected option should not include a click handler; unselected should
      refute html =~ ~r/value="email"[^>]*phx-click=/
      assert html =~ ~r/value="sms"[^>]*phx-click="change_channel"/
    end

    test "automatically integrates with form fields when field is provided" do
      form_data = %{"channel" => :email}
      form = to_form(form_data, as: "form")

      html =
        render_component(&Odyssey.odyssey_toggle_button/1, %{
          field: form[:channel],
          options: [
            %{label: "Email", value: :email},
            %{label: "Text Message", value: :sms},
            %{icon: "hero-phone", label: "Phone Call", value: :phone}
          ]
        })

      assert html =~ "Email"
      assert html =~ "Text Message"
      assert html =~ "Phone Call"
      assert html =~ "hero-phone"
      # Should have hidden input for form integration
      assert html =~ ~r/type="hidden"/
      assert html =~ ~r/name="form\[channel\]"/
      assert html =~ ~r/value="email"/
      # Should have the selected button highlighted (email)
      assert html =~ "bg-gray-50 text-blue-600"
      # Should have the LiveComponent event handler
      assert html =~ "odyssey_toggle_button_change"
    end

    test "handles mixed string and map options" do
      html =
        render_component(&Odyssey.odyssey_toggle_button/1, %{
          options: ["Minutes", %{icon: "hero-calendar", label: "Hours"}],
          selected: "Hours",
          on_change: "change_time_unit"
        })

      assert html =~ "Minutes"
      assert html =~ "Hours"
      assert html =~ "hero-calendar"
      # Minutes should not have an icon
      refute html =~ ~r/Minutes.*hero-/
    end

    test "correctly identifies selected option when using maps" do
      html =
        render_component(&Odyssey.odyssey_toggle_button/1, %{
          options: [%{icon: "hero-clock", label: "Minutes"}, %{icon: "hero-calendar", label: "Hours"}],
          selected: "Hours",
          on_change: "change_time_unit"
        })

      # The Hours button should have the selected styling
      assert html =~ "bg-gray-50 text-blue-600"
    end

    test "renders without fieldset when no label is provided" do
      html =
        render_component(&Odyssey.odyssey_toggle_button/1, %{
          options: ["Minutes", "Hours", "Days"],
          selected: "Minutes",
          on_change: "change_time_unit"
        })

      refute html =~ "<fieldset"
      refute html =~ "class=\"fieldset mb-2\""
      assert html =~ "class=\"inline-flex rounded-lg\""
    end

    test "renders with fieldset and label when label is provided" do
      html =
        render_component(&Odyssey.odyssey_toggle_button/1, %{
          options: ["Minutes", "Hours", "Days"],
          selected: "Minutes",
          on_change: "change_time_unit",
          label: "Time Unit"
        })

      assert html =~ "<fieldset"
      assert html =~ "class=\"fieldset mb-2\""
      assert html =~ "<label>"
      assert html =~ ~r/<span class="label mb-1">.*Time Unit.*<\/span>/s
      assert html =~ "class=\"inline-flex rounded-lg\""
    end

    test "form integration passes through label to toggle_button component" do
      form_data = %{"channel" => :email}
      form = to_form(form_data, as: "form")

      html =
        render_component(&Odyssey.odyssey_toggle_button/1, %{
          field: form[:channel],
          label: "Communication Channel",
          options: [
            %{label: "Email", value: :email},
            %{label: "Text Message", value: :sms}
          ]
        })

      assert html =~ "<fieldset"
      assert html =~ "class=\"fieldset mb-2\""
      assert html =~ "<label>"
      assert html =~ ~r/<span class="label mb-1">.*Communication Channel.*<\/span>/s
      assert html =~ "Email"
      assert html =~ "Text Message"
      # Should have hidden input for form integration
      assert html =~ ~r/type="hidden"/
      assert html =~ ~r/name="form\[channel\]"/
    end
  end
end
