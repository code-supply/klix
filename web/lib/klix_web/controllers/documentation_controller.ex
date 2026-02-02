defmodule KlixWeb.DocumentationController do
  use KlixWeb, :controller

  @suffix " - Klix Documentation"

  def index(conn, _params) do
    render(conn, :index, page_title: "Klix Documentation")
  end

  def show(conn, params) do
    case params["section"] do
      "klipper-config" ->
        render(conn, :"klipper-config", page_title: "Klipper Config#{@suffix}")

      "privacy-policy" ->
        render(conn, :"privacy-policy", page_title: "Privacy Policy#{@suffix}")

      _ ->
        raise Phoenix.Router.NoRouteError, conn: conn, router: KlixWeb.Router
    end
  end
end
