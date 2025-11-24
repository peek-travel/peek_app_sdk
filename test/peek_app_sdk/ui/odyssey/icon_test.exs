defmodule PeekAppSDK.UI.Odyssey.IconTest do
  use ExUnit.Case, async: true

  import Phoenix.LiveViewTest
  alias PeekAppSDK.UI.Odyssey

  test "renders hero icon variants as span" do
    html = render_component(&Odyssey.odyssey_icon/1, %{name: "hero-x-mark", class: "size-4"})

    assert html =~ "<span"
    assert html =~ "hero-x-mark"
  end

  test "renders odyssey svg icon variants" do
    icons = [
      %{name: "alert", tag: "<svg"},
      %{name: "warning", tag: "<svg"},
      %{name: "info", tag: "<svg"},
      %{name: "success", tag: "<svg"},
      %{name: "cancel", tag: "<svg"},
      %{name: "arrow-left", tag: "<svg"},
      %{name: "trashcan", tag: "<svg"},
      %{name: "loading", tag: "<svg"}
    ]

    Enum.each(icons, fn %{name: name, tag: tag} ->
      html = render_component(&Odyssey.odyssey_icon/1, %{name: name, class: "size-4"})
      assert html =~ tag
    end)
  end
end
