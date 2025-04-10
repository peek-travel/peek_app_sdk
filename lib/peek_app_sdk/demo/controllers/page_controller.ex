defmodule PeekAppSDK.Demo.PageController do
  use Phoenix.Controller, namespace: PeekAppSDK.Demo

  def home(conn, _params) do
    render(conn, "home.html", page_title: "Core Components Demo")
  end
end
