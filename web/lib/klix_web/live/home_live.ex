defmodule KlixWeb.HomeLive do
  use KlixWeb, :live_view

  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <header class="hero bg-base-300 h-70 rounded-xl">
        <div class="hero-content text-center">
          <div class="max-w-md">
            <h1 class="text-4xl font-bold">
              Spend time printing,<br />not fixing your printer's&nbsp;software.
            </h1>
            <p class="pt-4">
              Choose the Klipper plugins you need and download a tested image you can
              always upgrade or rebuild.
            </p>
          </div>
        </div>
      </header>

      <main class="px-20 py-4">
        <p class="py-2">
          Klix helps you create a custom Raspberry Pi image for your Klipper
          setup without needing to configure Linux yourself.
        </p>
        <p class="py-2">
          You pick the features you want, and Klix assembles a fresh, tested
          image with ready-to-go plugins.
        </p>
        <p class="py-2 text-right">
          <.link id="begin" navigate={~p"/images/new"} class="btn btn-lg btn-primary font-bold">
            Build My Image <.icon name="hero-arrow-right" class="size-6 shrink-0" />
          </.link>
        </p>
      </main>
    </Layouts.app>
    """
  end

  def mount(_params, _session, socket) do
    {:ok, assign(socket, page_title: "Custom 3D Printer OS Image")}
  end
end
