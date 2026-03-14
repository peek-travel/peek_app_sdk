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

    test "auto-extracts selected_ids from field value with atom-key maps" do
      field_value = [%{id: "p1", name: "Tour A"}, %{id: "p2", name: "Tour B"}]
      form = to_form(%{"products" => field_value}, as: :test)

      products = [
        %{id: "p1", name: "Tour A", color_hex: "#111"},
        %{id: "p2", name: "Tour B", color_hex: "#222"}
      ]

      html =
        render_component(
          fn assigns ->
            ~H"""
            <.odyssey_product_picker field={@form[:products]} products={@products} />
            """
          end,
          %{form: form, products: products}
        )

      assert html =~ ~r/value="p1,p2"/
      assert html =~ "Tour A"
    end

    test "auto-extracts selected_ids from field value with string-key maps" do
      field_value = [%{"id" => "p1"}, %{"id" => "p2"}]
      form = to_form(%{"products" => field_value}, as: :test)

      products = [
        %{id: "p1", name: "Tour A", color_hex: "#111"},
        %{id: "p2", name: "Tour B", color_hex: "#222"}
      ]

      html =
        render_component(
          fn assigns ->
            ~H"""
            <.odyssey_product_picker field={@form[:products]} products={@products} />
            """
          end,
          %{form: form, products: products}
        )

      assert html =~ ~r/value="p1,p2"/
    end

    test "auto-extracts selected_ids from Ecto.Changeset-like structs" do
      changeset_like = [
        %{__struct__: Ecto.Changeset, changes: %{id: "p1"}, data: nil, valid?: true, errors: []},
        %{__struct__: Ecto.Changeset, changes: %{id: "p2"}, data: nil, valid?: true, errors: []}
      ]

      form = to_form(%{"products" => changeset_like}, as: :test)
      products = [%{id: "p1", name: "A", color_hex: "#111"}, %{id: "p2", name: "B", color_hex: "#222"}]

      html =
        render_component(
          fn assigns ->
            ~H"""
            <.odyssey_product_picker field={@form[:products]} products={@products} />
            """
          end,
          %{form: form, products: products}
        )

      assert html =~ ~r/value="p1,p2"/
    end
  end

  describe "custom key attrs" do
    test "uses custom color_key" do
      form = to_form(%{"p" => nil}, as: :t)
      products = [%{id: "1", name: "A", hex: "#AA0000"}]

      html =
        render_component(
          fn assigns ->
            ~H"""
            <.odyssey_product_picker field={@form[:p]} products={@products} selected_ids={["1"]} color_key={:hex} />
            """
          end,
          %{form: form, products: products}
        )

      assert html =~ "background-color: #AA0000"
    end

    test "uses custom id_key and name_key" do
      form = to_form(%{"p" => nil}, as: :t)
      products = [%{product_id: "x1", title: "Kayak", color_hex: "#000"}]

      html =
        render_component(
          fn assigns ->
            ~H"""
            <.odyssey_product_picker
              field={@form[:p]}
              products={@products}
              selected_ids={["x1"]}
              id_key={:product_id}
              name_key={:title}
            />
            """
          end,
          %{form: form, products: products}
        )

      assert html =~ "Kayak"
      assert html =~ "data-product-id=\"x1\""
    end

    test "falls back to #888888 when color key is missing" do
      form = to_form(%{"p" => nil}, as: :t)
      products = [%{id: "1", name: "A"}]

      html =
        render_component(
          fn assigns ->
            ~H"""
            <.odyssey_product_picker field={@form[:p]} products={@products} selected_ids={["1"]} />
            """
          end,
          %{form: form, products: products}
        )

      assert html =~ "background-color: #888888"
    end
  end

  describe "extract_ids_from_field/1" do
    alias PeekAppSDK.UI.Odyssey.ProductPicker

    test "returns empty list for nil" do
      assert ProductPicker.extract_ids_from_field(nil) == []
    end

    test "returns empty list for non-list values" do
      assert ProductPicker.extract_ids_from_field("something") == []
      assert ProductPicker.extract_ids_from_field(42) == []
    end

    test "extracts ids from atom-key maps" do
      assert ProductPicker.extract_ids_from_field([%{id: "a"}, %{id: "b"}]) == ["a", "b"]
    end

    test "extracts ids from string-key maps" do
      assert ProductPicker.extract_ids_from_field([%{"id" => "x"}]) == ["x"]
    end

    test "extracts ids from changeset-like structs" do
      cs = %{__struct__: Ecto.Changeset, changes: %{id: "c1"}, data: nil, valid?: true, errors: []}
      assert ProductPicker.extract_ids_from_field([cs]) == ["c1"]
    end

    test "skips items without an id" do
      assert ProductPicker.extract_ids_from_field([%{name: "no id"}, %{id: "ok"}]) == ["ok"]
    end

    test "returns empty list for empty list" do
      assert ProductPicker.extract_ids_from_field([]) == []
    end
  end
end
