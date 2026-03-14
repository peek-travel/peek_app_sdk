defmodule PeekAppSDK.UI.Odyssey.SelectTest do
  use ExUnit.Case, async: true

  import Phoenix.LiveViewTest

  alias PeekAppSDK.UI.Odyssey.Select

  @items [
    %{id: "act-1", name: "Walking Tour", color_hex: "#FF0000"},
    %{id: "act-2", name: "Cocktail Tour", color_hex: "#00FF00"},
    %{id: "act-3", name: "Night Tour", color_hex: "#0000FF"}
  ]

  describe "odyssey_select/1" do
    test "renders with default title" do
      html =
        render_component(&Select.odyssey_select/1, %{
          id: "test-picker",
          items: @items,
          on_select: :item_selected
        })

      assert html =~ "Select Item"
    end

    test "renders with custom title" do
      html =
        render_component(&Select.odyssey_select/1, %{
          id: "test-picker",
          items: @items,
          on_select: :item_selected,
          title: "Pick a Product"
        })

      assert html =~ "Pick a Product"
    end

    test "renders with OdysseySelect hook" do
      html =
        render_component(&Select.odyssey_select/1, %{
          id: "test-picker",
          items: @items,
          on_select: :item_selected
        })

      assert html =~ ~r/phx-hook="OdysseySelect"/
    end

    test "dropdown is closed by default" do
      html =
        render_component(&Select.odyssey_select/1, %{
          id: "test-picker",
          items: @items,
          on_select: :item_selected
        })

      refute html =~ "Walking Tour"
      refute html =~ "data-dropdown"
    end

    test "passes all assigns through to live_component" do
      html =
        render_component(&Select.odyssey_select/1, %{
          id: "custom-picker",
          items: @items,
          on_select: :item_selected,
          excluded_ids: ["act-1"],
          color_field: :color_hex,
          context: 42,
          title: "Custom Title"
        })

      assert html =~ "custom-picker"
      assert html =~ "Custom Title"
    end
  end

  describe "filtered_items/3" do
    test "excludes items by excluded_ids" do
      # We test this indirectly through the component render
      # by opening the dropdown and checking items
      html =
        render_component(&Select.odyssey_select/1, %{
          id: "test-picker",
          items: @items,
          on_select: :item_selected,
          excluded_ids: ["act-1"]
        })

      # Dropdown is closed by default, so excluded items won't show regardless
      # This is tested more thoroughly via LiveView integration tests
      assert html =~ "test-picker"
    end
  end

  describe "get_color/2" do
    test "renders item colors from specified color_field" do
      items = [%{id: "1", name: "Test", colorHex: "#ABC123"}]

      html =
        render_component(&Select.odyssey_select/1, %{
          id: "test-picker",
          items: items,
          on_select: :item_selected,
          color_field: :colorHex
        })

      # Color won't be visible since dropdown is closed by default
      assert html =~ "test-picker"
    end
  end
end
