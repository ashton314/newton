defmodule NewtonWeb.PageController do
  use NewtonWeb, :controller

  def index(conn, _params) do
    render(conn, "welcome.html")
  end
end
