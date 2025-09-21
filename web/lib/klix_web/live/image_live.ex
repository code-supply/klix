defmodule KlixWeb.ImageLive do
  use KlixWeb, :live_view

  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <.header>
        {@image.hostname}
        <:subtitle>
          <.link class="link" navigate={~p"/images"}>
            <.icon name="hero-arrow-left" class="size-6 shrink-0" /> Back to Images
          </.link>
        </:subtitle>
      </.header>

      <main class="card card-border border-base-300">
        <dl class="card-body grid grid-cols-2 gap-4 text-xl">
          <dt class="font-bold text-right">Hostname</dt>
          <dd>{@image.hostname}</dd>

          <dt class="font-bold text-right">Timezone</dt>
          <dd>{@image.timezone}</dd>

          <dt class="font-bold text-right">KlipperScreen</dt>
          <dd>
            <.icon
              name={if @image.klipperscreen_enabled, do: "hero-check-circle", else: "hero-x-circle"}
              class="size-6"
            />
          </dd>

          <dt class="font-bold text-right">Plugins</dt>
          <dd>
            <ul id="plugins" class="flex flex-wrap gap-2">
              <li
                :for={{flag, name} <- Klix.Images.plugins(@image)}
                class="badge badge-info mt-1"
              >
                {name}
              </li>
            </ul>
          </dd>

          <dt class="font-bold text-right">Klipper Config</dt>
          <dd>
            <.link
              class="badge"
              href={"https://#{@image.klipper_config.type}.com/#{@image.klipper_config.owner}/#{@image.klipper_config.repo}/tree/main/#{@image.klipper_config.path}"}
            >
              {Klix.Images.KlipperConfig.type_name(@image.klipper_config)}
            </.link>
          </dd>
        </dl>
      </main>

      <section class="mt-4">
        <div>
          <h2 class="text-2xl pb-4">Builds</h2>
          <ol id="builds" class="list w-full">
            <li
              :for={{build, idx} <- Enum.with_index(@image.builds)}
              class="card card-border border-base-300"
            >
              <div class="card-body">
                <h3 class="text-2xl">{"##{length(@image.builds) - idx}"}</h3>
                <dl class="grid grid-cols-3">
                  <dt class="font-bold">Started</dt>
                  <dd class="col-span-2">{build.inserted_at |> format_datetime()}</dd>
                  <dt :if={Klix.Images.build_ready?(build)} class="font-bold">Completed</dt>
                  <dd :if={Klix.Images.build_ready?(build)} class="col-span-2">
                    {build.completed_at |> format_datetime()}
                  </dd>
                  <dt class="font-bold">Duration</dt>
                  <dd class="duration cols-span-2">{Klix.Images.build_duration(build, @now)}</dd>
                </dl>
                <div class="p-4">
                  <%= if Klix.Images.build_ready?(build) do %>
                    <.link
                      class="btn btn-primary float-right"
                      href={~p"/images/#{@image.id}/builds/#{build.id}/klix.img.zst"}
                      download
                    >
                      <.icon name="hero-arrow-down-tray" /> Download
                    </.link>
                  <% else %>
                    <div class="float-right loading loading-bars loading-xl">being prepared</div>
                  <% end %>
                </div>
              </div>
            </li>
          </ol>
        </div>
      </section>
    </Layouts.app>
    """
  end

  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  def handle_params(%{"id" => id}, _uri, socket) do
    image = Klix.Images.find!(socket.assigns.current_scope, id)

    Klix.Images.subscribe(image.id)

    now = tick_clock()

    {
      :noreply,
      socket
      |> assign(
        page_title: "#{image.hostname} image",
        image: image,
        images: Klix.Images.list(socket.assigns.current_scope),
        now: now
      )
    }
  end

  def handle_info([build_ready: updated_build], socket) do
    import Access

    {
      :noreply,
      update(socket, :image, fn image ->
        put_in(image, [key!(:builds), find(&(&1.id == updated_build.id))], updated_build)
      end)
    }
  end

  def handle_info({:tick, now}, socket) do
    tick_clock()
    {:noreply, assign(socket, now: now)}
  end

  defp tick_clock() do
    interval = :timer.seconds(1)
    now = DateTime.utc_now()
    next_tick = now |> DateTime.add(interval, :millisecond)

    Process.send_after(self(), {:tick, next_tick}, interval)

    now
  end
end
