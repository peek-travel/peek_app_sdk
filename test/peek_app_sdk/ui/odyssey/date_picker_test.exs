defmodule PeekAppSDK.UI.Odyssey.DatePickerTest do
  use ExUnit.Case, async: true

  import Phoenix.Component
  import Phoenix.LiveViewTest

  alias PeekAppSDK.UI.Odyssey

  describe "odyssey_date_picker/1" do
    test "renders standalone date picker with label and icons" do
      html =
        render_component(&Odyssey.odyssey_date_picker/1, %{
          id: "start_date",
          name: "start_date",
          value: ~D[2025-01-01],
          label: "Start date"
        })

      assert html =~ ~s(<fieldset class="fieldset mb-2">)
      assert html =~ "Start date"
      assert html =~ ~s(type="date")
      assert html =~ ~s(name="start_date")
      assert html =~ ~s(id="start_date")
      assert html =~ "2025-01-01"
      assert html =~ "hero-calendar-days"
      assert html =~ "hero-chevron-down"
    end

    test "applies error class and renders error messages" do
      html =
        render_component(&Odyssey.odyssey_date_picker/1, %{
          id: "expiration_date",
          name: "expiration_date",
          value: "",
          label: "Expiration date",
          errors: ["is required"]
        })

      assert html =~ "input-error"
      assert html =~ ~s(class="mt-1.5 flex gap-2 items-center text-sm text-error")
      assert html =~ "hero-exclamation-circle"
      assert html =~ "is required"
    end

    test "integrates with Phoenix.HTML.Form field" do
      form_data = %{"start_date" => ~D[2025-02-02]}
      form = to_form(form_data, as: "form")

      html =
        render_component(&Odyssey.odyssey_date_picker/1, %{
          field: form[:start_date],
          label: "Start date",
          required: true
        })

      assert html =~ ~s(name="form[start_date]")
      assert html =~ ~s(id="form_start_date")
      assert html =~ "2025-02-02"
      assert html =~ "Start date"
    end
  end
end
