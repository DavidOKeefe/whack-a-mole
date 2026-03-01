defmodule WhackAMoleWeb.PageController do
  use WhackAMoleWeb, :controller

  def home(conn, _params) do
    render(conn, :home)
  end
end
