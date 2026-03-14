defmodule PeekAppSDK.UI.Odyssey.ProductPickerTest do
  use ExUnit.Case, async: true

  import Phoenix.Component
  import Phoenix.LiveViewTest
  import PeekAppSDK.UI.Odyssey

  describe "odyssey_product_picker/1" do
    test "renders with products and no selection (all mode)" do
      form = to_form(%{"whitelisted_products" => nil}, as: :campaign)

      products = [
        %{id: "p1", name: "Kayak Tour", color_hex: "#FF5733"},
        %{id: "p2", name: "Snorkel Trip", color_hex: "#33FF57"}
      ]

      html =
        render_component(
          fn assigns ->
            ~H"""
            <.form for={@form}>
              <.odyssey_product_picker field={@form[:whitelisted_products]} products={@products} />
            </.form>
            """
          end,
          %{form: form, products: products}
        )

      assert html =~ ~r/<input[^>]*type="hidden"[^>]*name="campaign\[whitelisted_products\]"/
      assert html =~ "All Products"
      assert html =~ "Specific Products"
      refute html =~ "Kayak Tour"
    end

    test "renders with selected_ids in specific mode" do
      form = to_form(%{"whitelisted_products" => nil}, as: :campaign)

      products = [
        %{id: "p1", name: "Kayak Tour", color_hex: "#FF5733"},
        %{id: "p2", name: "Snorkel Trip", color_hex: "#33FF57"}
      ]

      html =
        render_component(
          fn assigns ->
            ~H"""
            <.odyssey_product_picker
              field={@form[:whitelisted_products]}
              products={@products}
              selected_ids={["p1"]}
            />
            """
          end,
          %{form: form, products: products}
        )

      assert html =~ "Kayak Tour"
      assert html =~ "Snorkel Trip"
      assert html =~ ~r/value="p1"/
      assert html =~ "#FF5733"
      assert html =~ "#33FF57"
    end

    test "renders with custom toggle labels" do
      form = to_form(%{"products" => nil}, as: :test)

      html =
        render_component(
          fn assigns ->
            ~H"""
            <.odyssey_product_picker
              field={@form[:products]}
              products={[]}
              all_label="All Events"
              specific_label="Specific Events"
            />
            """
          end,
          %{form: form}
        )

      assert html =~ "All Events"
      assert html =~ "Specific Events"
    end

    test "renders disabled state" do
      form = to_form(%{"products" => nil}, as: :test)

      products = [%{id: "p1", name: "Tour", color_hex: "#000"}]

      html =
        render_component(
          fn assigns ->
            ~H"""
            <.odyssey_product_picker
              field={@form[:products]}
              products={@products}
              selected_ids={["p1"]}
              disabled={true}
            />
            """
          end,
          %{form: form, products: products}
        )

      assert html =~ "disabled"
    end

    test "generates unique component ID based on form field" do
      form = to_form(%{"activity_ids" => nil}, as: :booking)

      html =
        render_component(
          fn assigns ->
            ~H"""
            <.odyssey_product_picker field={@form[:activity_ids]} products={[]} />
            """
          end,
          %{form: form}
        )

      assert html =~ ~r/id="booking_activity_ids_product_picker"/
    end

    test "renders with custom id" do
      form = to_form(%{"products" => nil}, as: :test)

      html =
        render_component(
          fn assigns ->
            ~H"""
            <.odyssey_product_picker field={@form[:products]} products={[]} id="my-custom-picker" />
            """
          end,
          %{form: form}
        )

      assert html =~ ~r/id="my-custom-picker"/
    end

    test "renders with label" do
      form = to_form(%{"products" => nil}, as: :test)

      html =
        render_component(
          fn assigns ->
            ~H"""
            <.odyssey_product_picker field={@form[:products]} products={[]} label="Apply Products" />
            """
          end,
          %{form: form}
        )

      assert html =~ "Apply Products"
    end

    test "encodes multiple selected_ids as comma-separated value" do
      form = to_form(%{"products" => nil}, as: :test)

      products = [
        %{id: "p1", name: "Tour A", color_hex: "#111"},
        %{id: "p2", name: "Tour B", color_hex: "#222"}
      ]

      html =
        render_component(
          fn assigns ->
            ~H"""
            <.odyssey_product_picker
              field={@form[:products]}
              products={@products}
              selected_ids={["p1", "p2"]}
            />
            """
          end,
          %{form: form, products: products}
        )

      assert html =~ ~r/value="p1,p2"/
    end
  end
end
