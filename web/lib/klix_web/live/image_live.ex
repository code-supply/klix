defmodule KlixWeb.ImageLive do
  use KlixWeb, :live_view

  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <.header>
        {@image.hostname}
        <:subtitle>
          <.link navigate={~p"/images"}>
            <.icon name="hero-arrow-left" class="size-6 shrink-0" /> Back to Images
          </.link>
        </:subtitle>
      </.header>

      <main class="bg-neutral text-neutral-content p-4">
        <dl class="grid grid-cols-2 gap-4 text-xl">
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
            <ul id="plugins" class="flex gap-2">
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

      <section class="mt-4 bg-secondary text-left p-4 rounded-xl">
        <h2 class="text-2xl pb-4">Builds</h2>
        <table id="builds" class="rounded-xl bg-base-300 w-full">
          <thead>
            <tr>
              <th class="py-2 px-4">Started</th>
              <th class="py-2 px-4">Completed</th>
              <th class="py-2 px-4 text-right">Duration (inc. queue)</th>
              <th class="py-2 px-4"></th>
            </tr>
          </thead>
          <tbody>
            <tr :for={build <- @image.builds}>
              <td class="p-4">{build.inserted_at}</td>
              <td class="p-4">{build.completed_at}</td>
              <td class="duration p-4 text-right">{Klix.Images.build_duration(build, @now)}</td>
              <td class="p-4">
                <%= if Klix.Images.build_ready?(build) do %>
                  <.link
                    class="btn btn-primary w-full"
                    href={~p"/images/#{@image.id}/builds/#{build.id}/klix.img.zst"}
                    download
                  >
                    <.icon name="hero-arrow-down-tray" /> Download
                  </.link>
                <% else %>
                  <div class="loading loading-bars loading-xl">being prepared</div>
                <% end %>
              </td>
            </tr>
          </tbody>
        </table>
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
