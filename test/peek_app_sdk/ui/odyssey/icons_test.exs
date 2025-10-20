defmodule PeekAppSDK.UI.Odyssey.IconsTest do
  use ExUnit.Case, async: true

  import Phoenix.Component
  import Phoenix.LiveViewTest
  import PeekAppSDK.UI.Odyssey.Icons

  describe "alert_icon/1" do
    test "renders alert icon" do
      html =
        render_component(
          fn assigns ->
            ~H"""
            <.alert_icon />
            """
          end,
          %{}
        )

      assert html =~ "<svg"
      assert html =~ "viewBox"
    end

    test "renders alert icon with custom class" do
      html =
        render_component(
          fn assigns ->
            ~H"""
            <.alert_icon class="w-8 h-8" />
            """
          end,
          %{}
        )

      assert html =~ "w-8 h-8"
      assert html =~ "<svg"
    end
  end

  describe "warning_icon/1" do
    test "renders warning icon" do
      html =
        render_component(
          fn assigns ->
            ~H"""
            <.warning_icon />
            """
          end,
          %{}
        )

      assert html =~ "<svg"
      assert html =~ "viewBox"
    end

    test "renders warning icon with custom class" do
      html =
        render_component(
          fn assigns ->
            ~H"""
            <.warning_icon class="w-6 h-6" />
            """
          end,
          %{}
        )

      assert html =~ "w-6 h-6"
      assert html =~ "<svg"
    end
  end

  describe "info_icon/1" do
    test "renders info icon" do
      html =
        render_component(
          fn assigns ->
            ~H"""
            <.info_icon />
            """
          end,
          %{}
        )

      assert html =~ "<svg"
      assert html =~ "viewBox"
    end

    test "renders info icon with custom class" do
      html =
        render_component(
          fn assigns ->
            ~H"""
            <.info_icon class="w-5 h-5" />
            """
          end,
          %{}
        )

      assert html =~ "w-5 h-5"
      assert html =~ "<svg"
    end
  end

  describe "success_icon/1" do
    test "renders success icon" do
      html =
        render_component(
          fn assigns ->
            ~H"""
            <.success_icon />
            """
          end,
          %{}
        )

      assert html =~ "<svg"
      assert html =~ "viewBox"
    end

    test "renders success icon with custom class" do
      html =
        render_component(
          fn assigns ->
            ~H"""
            <.success_icon class="w-7 h-7" />
            """
          end,
          %{}
        )

      assert html =~ "w-7 h-7"
      assert html =~ "<svg"
    end
  end

  describe "cancel_icon/1" do
    test "renders cancel icon" do
      html =
        render_component(
          fn assigns ->
            ~H"""
            <.cancel_icon />
            """
          end,
          %{}
        )

      assert html =~ "<svg"
      assert html =~ "viewBox"
    end

    test "renders cancel icon with custom class" do
      html =
        render_component(
          fn assigns ->
            ~H"""
            <.cancel_icon class="w-4 h-4" />
            """
          end,
          %{}
        )

      assert html =~ "w-4 h-4"
      assert html =~ "<svg"
    end
  end
end
