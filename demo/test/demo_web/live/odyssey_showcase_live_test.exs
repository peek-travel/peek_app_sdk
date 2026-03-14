defmodule DemoWeb.OdysseyShowcaseLiveTest do
  use DemoWeb.ConnCase

  import Phoenix.LiveViewTest

  describe "product picker" do
    test "renders product picker in forms tab", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/")

      html =
        view
        |> element("[phx-click='change_tab'][phx-value-tab='forms']")
        |> render_click()

      assert html =~ "Product Picker Component"
      assert html =~ "product-picker-form"
      assert html =~ "All Products"
      assert html =~ "Specific Products"
    end

    test "product picker starts in 'all' mode by default", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/")

      view
      |> element("[phx-click='change_tab'][phx-value-tab='forms']")
      |> render_click()

      html = render(view)

      # In "all" mode, individual product checkboxes should not be visible
      refute html =~ "Wine Tasting"
      refute html =~ "Cooking Class"
    end

    test "toggling to 'specific' shows product checkboxes", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/")

      view
      |> element("[phx-click='change_tab'][phx-value-tab='forms']")
      |> render_click()

      html =
        view
        |> element("button[value='specific']")
        |> render_click()

      assert html =~ "Wine Tasting"
      assert html =~ "Cooking Class"
      assert html =~ "City Tour"
      assert html =~ "Sunset Cruise"
    end

    test "toggling back to 'all' hides product checkboxes", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/")

      view
      |> element("[phx-click='change_tab'][phx-value-tab='forms']")
      |> render_click()

      # Toggle to specific first
      view
      |> element("button[value='specific']")
      |> render_click()

      # Toggle back to all
      html =
        view
        |> element("button[value='all']")
        |> render_click()

      refute html =~ "Wine Tasting"
      refute html =~ "Cooking Class"
    end

    test "product picker renders with label", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/")

      html =
        view
        |> element("[phx-click='change_tab'][phx-value-tab='forms']")
        |> render_click()

      assert html =~ "Apply to"
    end
  end
end

