defmodule PeekAppSDK.UI.OdysseyTest do
  use ExUnit.Case
  import Phoenix.LiveViewTest

  describe "odyssey_toggle_button component" do
    test "renders all options" do
      html =
        render_component(&PeekAppSDK.UI.Odyssey.odyssey_toggle_button/1, %{
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
        render_component(&PeekAppSDK.UI.Odyssey.odyssey_toggle_button/1, %{
          options: ["Minutes", "Hours", "Days"],
          selected: "Hours",
          on_change: "change_time_unit"
        })

      assert html =~ "bg-white text-blue-700 shadow-sm"
    end

    test "shows unselected options with gray styling" do
      html =
        render_component(&PeekAppSDK.UI.Odyssey.odyssey_toggle_button/1, %{
          options: ["Minutes", "Hours", "Days"],
          selected: "Days",
          on_change: "change_time_unit"
        })

      assert html =~ "bg-transparent text-gray-600 hover:text-gray-900 cursor-pointer"
    end
  end
end
