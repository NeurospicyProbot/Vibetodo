defmodule VibetodoWeb.PageController do
  use VibetodoWeb, :controller

  def home(conn, _params) do
    render(conn, :home)
  end
end
