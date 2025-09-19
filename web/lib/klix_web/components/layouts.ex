defmodule KlixWeb.Layouts do
  @moduledoc """
  This module holds layouts and related functionality
  used by your application.
  """
  use KlixWeb, :html

  # Embed all files in layouts/* within this module.
  # The default root.html.heex file contains the HTML
  # skeleton of your application, namely HTML headers
  # and other static content.
  embed_templates "layouts/*"

  @doc """
  Renders your app layout.

  This function is typically invoked from every template,
  and it often contains your application menu, sidebar,
  or similar.

  ## Examples

      <Layouts.app flash={@flash}>
        <h1>Content</h1>
      </Layouts.app>

  """
  attr :flash, :map, required: true, doc: "the map of flash messages"

  attr :current_scope, :map,
    default: nil,
    doc: "the current [scope](https://hexdocs.pm/phoenix/scopes.html)"

  slot :inner_block, required: true

  def app(assigns) do
    ~H"""
    <div class="drawer">
      <input id="main-nav" type="checkbox" class="drawer-toggle" />
      <div class="drawer-content">
        <header class="navbar fixed top-0 bg-base-200 h-13 z-40 shadow flex justify-between">
          <div class="flex-none">
            <label for="main-nav" class="btn btn-ghost btn-circle drawer-button">
              <svg
                xmlns="http://www.w3.org/2000/svg"
                fill="none"
                viewBox="0 0 24 24"
                class="inline-block h-5 w-5 stroke-current"
              >
                <path
                  stroke-linecap="round"
                  stroke-linejoin="round"
                  stroke-width="2"
                  d="M4 6h16M4 12h16M4 18h16"
                >
                </path>
              </svg>
            </label>
          </div>
          <div class="flex-1">
            <.link href={~p"/"} class="text-2xl p-4 leading-12">Klix</.link>
          </div>
          <div class="dropdown dropdown-end">
            <div tabindex="0" role="button" class="btn mx-3 my-2 overflow-hidden">
              <%= if @current_scope do %>
                {@current_scope.user.email}
              <% else %>
                Account
              <% end %>
            </div>
            <ul
              tabindex="0"
              class="dropdown-content menu bg-base-200 rounded-box z-1 shadow-sm w-40 mt-1 mr-4"
            >
              <%= if @current_scope do %>
                <li><.link href={~p"/users/settings"}>Settings</.link></li>
                <li><.link href={~p"/users/log-out"} method="delete">Log out</.link></li>
              <% else %>
                <li><.link href={~p"/users/register"}>Register</.link></li>
                <li><.link href={~p"/users/log-in"}>Log in</.link></li>
              <% end %>
            </ul>
          </div>
        </header>

        <main class="md:w-1/2 w-3/4 m-auto pb-7 pt-20">
          {render_slot(@inner_block)}
        </main>

        <.flash_group flash={@flash} />

        <footer class="footer sm:footer-horizontal bg-neutral text-neutral-content p-10 pb-14">
          <div></div>
          <nav>
            <h6 class="footer-title">Developers</h6>
            <a class="link link-hover">Code Supply</a>
            <a class="link link-hover">Andrew Bruce</a>
          </nav>
          <nav>
            <h6 class="footer-title">Source</h6>
            <a class="link link-hover" href="https://github.com/code-supply/klix">GitHub</a>
            <a class="link link-hover" href="https://github.com/code-supply/klix/blob/main/LICENSE">
              License
            </a>
          </nav>
        </footer>
      </div>

      <div class="drawer-side z-50">
        <label for="main-nav" aria-label="close sidebar" class="drawer-overlay"></label>
        <ul class="menu bg-base-200 text-base-content min-h-full w-80 p-4">
          <li><.link navigate={~p"/images"}>Images</.link></li>
        </ul>
      </div>
    </div>
    """
  end

  @doc """
  Shows the flash group with standard titles and content.

  ## Examples

      <.flash_group flash={@flash} />
  """
  attr :flash, :map, required: true, doc: "the map of flash messages"
  attr :id, :string, default: "flash-group", doc: "the optional id of flash container"

  def flash_group(assigns) do
    ~H"""
    <div id={@id} aria-live="polite">
      <.flash kind={:info} flash={@flash} />
      <.flash kind={:error} flash={@flash} />

      <.flash
        id="client-error"
        kind={:error}
        title={gettext("We can't find the internet")}
        phx-disconnected={show(".phx-client-error #client-error") |> JS.remove_attribute("hidden")}
        phx-connected={hide("#client-error") |> JS.set_attribute({"hidden", ""})}
        hidden
      >
        {gettext("Attempting to reconnect")}
        <.icon name="hero-arrow-path" class="ml-1 size-3 motion-safe:animate-spin" />
      </.flash>

      <.flash
        id="server-error"
        kind={:error}
        title={gettext("Something went wrong!")}
        phx-disconnected={show(".phx-server-error #server-error") |> JS.remove_attribute("hidden")}
        phx-connected={hide("#server-error") |> JS.set_attribute({"hidden", ""})}
        hidden
      >
        {gettext("Attempting to reconnect")}
        <.icon name="hero-arrow-path" class="ml-1 size-3 motion-safe:animate-spin" />
      </.flash>
    </div>
    """
  end

  @doc """
  Provides dark vs light theme toggle based on themes defined in app.css.

  See <head> in root.html.heex which applies the theme before page load.
  """
  def theme_toggle(assigns) do
    ~H"""
    <div class="card relative flex flex-row items-center border-2 border-base-300 bg-base-300 rounded-full">
      <div class="absolute w-1/3 h-full rounded-full border-1 border-base-200 bg-base-100 brightness-200 left-0 [[data-theme=light]_&]:left-1/3 [[data-theme=dark]_&]:left-2/3 transition-[left]" />

      <button
        class="flex p-2 cursor-pointer w-1/3"
        phx-click={JS.dispatch("phx:set-theme")}
        data-phx-theme="system"
      >
        <.icon name="hero-computer-desktop-micro" class="size-4 opacity-75 hover:opacity-100" />
      </button>

      <button
        class="flex p-2 cursor-pointer w-1/3"
        phx-click={JS.dispatch("phx:set-theme")}
        data-phx-theme="light"
      >
        <.icon name="hero-sun-micro" class="size-4 opacity-75 hover:opacity-100" />
      </button>

      <button
        class="flex p-2 cursor-pointer w-1/3"
        phx-click={JS.dispatch("phx:set-theme")}
        data-phx-theme="dark"
      >
        <.icon name="hero-moon-micro" class="size-4 opacity-75 hover:opacity-100" />
      </button>
    </div>
    """
  end
end
