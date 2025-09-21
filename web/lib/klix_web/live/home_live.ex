defmodule KlixWeb.HomeLive do
  use KlixWeb, :live_view

  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <header class="hero min-h-fit rounded-xl bg-repeat bg-auto bg-[url(/images/printer-pattern.png)] shadow-xl">
        <div class="hero-content px-9 text-center backdrop-blur-xs bg-white/80 rounded-xl">
          <h1 class="md:text-5xl/16 text-3xl/10 font-bold text-black">
            <span class="text-7xl/24">Klix</span>
            <br /> Spend time printing,<br />not fixing your<br />printer's&nbsp;software.
          </h1>
        </div>
      </header>

      <main class="md:px-20 md:text-2xl/11 text-lg py-7">
        <p class="py-4">
          Klix lets you create custom Raspberry Pi images for your Klipper
          3D printer without needing to configure Linux yourself.
        </p>
        <p class="py-4">
          Choose Klipper plugins, KlipperScreen and network config so they're correct on first boot.
          Reconfigure, upgrade and rebuild your image any time.
        </p>
        <p class="py-4 text-right">
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
