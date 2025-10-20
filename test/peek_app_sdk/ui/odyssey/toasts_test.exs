defmodule PeekAppSDK.UI.Odyssey.ToastsTest do
  use ExUnit.Case, async: true

  import Phoenix.Component
  import Phoenix.LiveViewTest
  import PeekAppSDK.UI.Odyssey.Toasts

  describe "toast/1" do
    test "renders toast with success type" do
      html =
        render_component(
          fn assigns ->
            ~H"""
            <.toast type="success" id="success-toast">
              <:title>Success</:title>
              <:text>Done</:text>
            </.toast>
            """
          end,
          %{}
        )

      assert html =~ "Success"
      assert html =~ "Done"
      assert html =~ "border-l-success-300"
      assert html =~ "fixed"
      assert html =~ "id=\"success-toast\""
      assert html =~ "phx-hook=\"ToastHook\""
    end

    test "renders toast with error type" do
      html =
        render_component(
          fn assigns ->
            ~H"""
            <.toast type="error" id="error-toast">
              <:title>Error</:title>
              <:text>Failed</:text>
            </.toast>
            """
          end,
          %{}
        )

      assert html =~ "Error"
      assert html =~ "Failed"
      assert html =~ "border-l-danger-300"
    end

    test "renders toast with warning type" do
      html =
        render_component(
          fn assigns ->
            ~H"""
            <.toast type="warning" id="warning-toast">
              <:title>Warning</:title>
              <:text>Careful</:text>
            </.toast>
            """
          end,
          %{}
        )

      assert html =~ "Warning"
      assert html =~ "Careful"
      assert html =~ "border-l-warning-300"
    end

    test "renders toast with info type" do
      html =
        render_component(
          fn assigns ->
            ~H"""
            <.toast type="info" id="info-toast">
              <:title>Info</:title>
              <:text>Note</:text>
            </.toast>
            """
          end,
          %{}
        )

      assert html =~ "Info"
      assert html =~ "Note"
      assert html =~ "border-l-interaction-300"
    end

    test "renders toast with default info type" do
      html =
        render_component(
          fn assigns ->
            ~H"""
            <.toast id="default-toast">
              <:title>Default</:title>
              <:text>Info</:text>
            </.toast>
            """
          end,
          %{}
        )

      assert html =~ "Default"
      assert html =~ "border-l-interaction-300"
    end

    test "renders toast with positioning classes" do
      html =
        render_component(
          fn assigns ->
            ~H"""
            <.toast type="success" id="pos-toast">
              <:title>Test</:title>
              <:text>Message</:text>
            </.toast>
            """
          end,
          %{}
        )

      assert html =~ "fixed"
      assert html =~ "top-4"
      assert html =~ "right-4"
      assert html =~ "z-50"
      assert html =~ "w-96"
    end

    test "renders toast with styling classes" do
      html =
        render_component(
          fn assigns ->
            ~H"""
            <.toast type="success" id="style-toast">
              <:title>Test</:title>
              <:text>Message</:text>
            </.toast>
            """
          end,
          %{}
        )

      assert html =~ "bg-white"
      assert html =~ "rounded-lg"
      assert html =~ "shadow-lg"
      assert html =~ "border-l-4"
      assert html =~ "p-4"
    end

    test "renders close button with data-close-toast" do
      html =
        render_component(
          fn assigns ->
            ~H"""
            <.toast type="success" id="close-toast">
              <:title>Test</:title>
              <:text>Message</:text>
            </.toast>
            """
          end,
          %{}
        )

      assert html =~ "data-close-toast"
      assert html =~ "type=\"button\""
    end

    test "renders with unknown type defaults to info" do
      html =
        render_component(
          fn assigns ->
            ~H"""
            <.toast type="unknown" id="unknown-toast">
              <:title>Test</:title>
              <:text>Message</:text>
            </.toast>
            """
          end,
          %{}
        )

      assert html =~ "border-l-interaction-300"
    end
  end
end
