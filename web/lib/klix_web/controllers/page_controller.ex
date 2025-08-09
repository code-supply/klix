defmodule KlixWeb.PageController do
  use KlixWeb, :controller

  def home(conn, _params) do
    render(conn, :home)
  end
end
