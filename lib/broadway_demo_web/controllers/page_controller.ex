defmodule BroadwayDemoWeb.PageController do
  use BroadwayDemoWeb, :controller

  def index(conn, _params) do
    render(conn, "index.html")
  end
end
