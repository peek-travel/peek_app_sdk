defmodule PeekAppSDK.UI.Odyssey.PrefixInputTest do
  use ExUnit.Case, async: true

  import Phoenix.Component
  import Phoenix.LiveViewTest

  alias PeekAppSDK.UI.Odyssey

  describe "odyssey_prefix_input/1" do
    test "renders standalone prefix input with label and prefix" do
      html =
        render_component(&Odyssey.odyssey_prefix_input/1, %{
          id: "discount",
          name: "discount",
          value: "10",
          prefix: "$",
          label: "Discount amount"
        })

      assert html =~ ~s(<fieldset class="fieldset mb-2">)
      assert html =~ "Discount amount"
      assert html =~ "$"
      assert html =~ ~s(name="discount")
      assert html =~ ~s(id="discount")
      assert html =~ ~s(value="10")
      assert html =~ "flex-1 rounded-r-md !rounded-l-none border-l-0 input"
    end

    test "applies error class and renders error messages" do
      html =
        render_component(&Odyssey.odyssey_prefix_input/1, %{
          id: "discount",
          name: "discount",
          value: "",
          prefix: "$",
          label: "Discount amount",
          errors: ["is required"]
        })

      # input-error class is added when errors are present
      assert html =~ "input-error"
      # error container and icon
      assert html =~ ~s(class="mt-1.5 flex gap-2 items-center text-sm text-error")
      assert html =~ "hero-exclamation-circle"
      assert html =~ "is required"
    end

    test "renders validation error message" do
      html =
        render_component(&Odyssey.odyssey_prefix_input/1, %{
          id: "input",
          name: "input",
          value: "a",
          prefix: "$",
          label: "Label",
          errors: ["must be a valid number"]
        })

      assert html =~ "must be a valid number"
    end

    test "integrates with Phoenix.HTML.Form field" do
      form_data = %{"discount" => "25"}
      form = to_form(form_data, as: "form")

      html =
        render_component(&Odyssey.odyssey_prefix_input/1, %{
          field: form[:discount],
          prefix: "$",
          label: "Discount amount",
          type: "number"
        })

      # field-based name/id/value come from the form field
      assert html =~ ~s(name="form[discount]")
      assert html =~ ~s(id="form_discount")
      assert html =~ ~s(value="25")
      # still renders prefix and label
      assert html =~ "Discount amount"
      assert html =~ "$"
    end
  end
end
