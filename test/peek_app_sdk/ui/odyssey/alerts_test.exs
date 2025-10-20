defmodule PeekAppSDK.UI.Odyssey.AlertsTest do
  use ExUnit.Case, async: true

  import Phoenix.Component
  import Phoenix.LiveViewTest
  import PeekAppSDK.UI.Odyssey.Alerts

  describe "alert/1" do
    test "renders alert with success type" do
      html =
        render_component(
          fn assigns ->
            ~H"""
            <.alert type="success">
              <:title>Success</:title>
              <:message>Done</:message>
            </.alert>
            """
          end,
          %{}
        )

      assert html =~ "Success"
      assert html =~ "Done"
      assert html =~ "border-success-300"
    end

    test "renders alert with error type" do
      html =
        render_component(
          fn assigns ->
            ~H"""
            <.alert type="error">
              <:title>Error</:title>
              <:message>Failed</:message>
            </.alert>
            """
          end,
          %{}
        )

      assert html =~ "Error"
      assert html =~ "Failed"
      assert html =~ "border-danger-300"
    end

    test "renders alert with warning type" do
      html =
        render_component(
          fn assigns ->
            ~H"""
            <.alert type="warning">
              <:title>Warning</:title>
              <:message>Careful</:message>
            </.alert>
            """
          end,
          %{}
        )

      assert html =~ "Warning"
      assert html =~ "Careful"
      assert html =~ "border-warning-300"
    end

    test "renders alert with info type" do
      html =
        render_component(
          fn assigns ->
            ~H"""
            <.alert type="info">
              <:title>Info</:title>
              <:message>Note</:message>
            </.alert>
            """
          end,
          %{}
        )

      assert html =~ "Info"
      assert html =~ "Note"
      assert html =~ "border-info-300"
    end

    test "renders alert with default info type" do
      html =
        render_component(
          fn assigns ->
            ~H"""
            <.alert>
              <:title>Default</:title>
              <:message>Info</:message>
            </.alert>
            """
          end,
          %{}
        )

      assert html =~ "Default"
      assert html =~ "border-info-300"
    end

    test "renders alert with action link" do
      html =
        render_component(
          fn assigns ->
            ~H"""
            <.alert type="info" action_text="Learn" action_url="https://example.com">
              <:title>Info</:title>
              <:message>More</:message>
            </.alert>
            """
          end,
          %{}
        )

      assert html =~ "Learn"
      assert html =~ "https://example.com"
      assert html =~ "target=\"_blank\""
    end

    test "renders with correct Tailwind classes" do
      html =
        render_component(
          fn assigns ->
            ~H"""
            <.alert type="success">
              <:title>Test</:title>
              <:message>Message</:message>
            </.alert>
            """
          end,
          %{}
        )

      assert html =~ "max-w-4xl"
      assert html =~ "bg-white"
      assert html =~ "rounded-lg"
      assert html =~ "shadow-sm"
      assert html =~ "border-l-4"
      assert html =~ "flex items-start"
      assert html =~ "flex-1"
      assert html =~ "font-medium"
      assert html =~ "text-base"
    end

    test "renders with unknown type defaults to info" do
      html =
        render_component(
          fn assigns ->
            ~H"""
            <.alert type="unknown">
              <:title>Test</:title>
              <:message>Message</:message>
            </.alert>
            """
          end,
          %{}
        )

      assert html =~ "border-info-300"
    end
  end
end
