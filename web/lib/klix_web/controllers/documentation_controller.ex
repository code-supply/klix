defmodule KlixWeb.DocumentationController do
  use KlixWeb, :controller

  def index(conn, _params) do
    render(conn, :index)
  end

  def show(conn, params) do
    :"klipper-config"
    render(conn, String.to_existing_atom(params["section"]))
  end
end
