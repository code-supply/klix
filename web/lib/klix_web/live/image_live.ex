defmodule KlixWeb.ImageLive do
  use KlixWeb, :live_view

  alias Klix.Images

  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <.header>
        {@image.hostname}
        <:subtitle>
          <div class="breadcrumbs text-sm">
            <ol>
              <li>
                <.link class="link" navigate={~p"/"}>Home</.link>
              </li>
              <li>
                <.link class="link" navigate={~p"/images"}>Your Images</.link>
              </li>
              <li>{@image.hostname}</li>
            </ol>
          </div>
        </:subtitle>
      </.header>

      <div class="md:grid md:grid-cols-2 gap-4">
        <section class="bg-base-100 card card-border border-base-300 mb-4">
          <div class="card-body">
            <h3 class="card-title">
              <.icon name="hero-tag" class="size-6" /> Printer details
            </h3>
            <dl class="grid grid-cols-2 gap-2 pt-1">
              <dt class="font-bold">Hostname</dt>
              <dd>{@image.hostname}</dd>

              <dt class="font-bold">Timezone</dt>
              <dd>{@image.timezone}</dd>

              <dt class="font-bold">KlipperScreen</dt>
              <dd>
                <.icon
                  name={
                    if @image.klipperscreen_enabled, do: "hero-check-circle", else: "hero-x-circle"
                  }
                  class="size-6"
                />
              </dd>

              <dt class="font-bold">Plugins</dt>
              <dd>
                <ul id="plugins" class="flex flex-wrap gap-2">
                  <li
                    :for={{flag, name} <- Images.plugins(@image)}
                    class="badge badge-info mt-1"
                  >
                    {name}
                  </li>
                </ul>
              </dd>

              <dt class="font-bold">Klipper Config</dt>
              <dd>
                <.link
                  class="badge"
                  href={"https://#{@image.klipper_config.type}.com/#{@image.klipper_config.owner}/#{@image.klipper_config.repo}/tree/main/#{@image.klipper_config.path}"}
                >
                  {Images.KlipperConfig.type_name(@image.klipper_config)}
                </.link>
              </dd>
            </dl>
          </div>
        </section>

        <section>
          <ol id="builds">
            <li
              :for={{build, idx} <- Enum.with_index(@image.builds)}
              class="bg-base-100 card card-border border-base-300 card-md"
            >
              <div class="card-body">
                <h3 class="card-title">
                  <.icon name="hero-cube" class="size-6" /> Build {"##{length(@image.builds) - idx}"}
                </h3>
                <dl class="grid grid-cols-3">
                  <dt class="font-bold">Started</dt>
                  <dd class="col-span-2">{build.inserted_at |> format_datetime()}</dd>
                  <dt :if={Images.build_ready?(build)} class="font-bold">Completed</dt>
                  <dd :if={Images.build_ready?(build)} class="col-span-2">
                    {build.completed_at |> format_datetime()}
                  </dd>
                  <dt class="font-bold">Duration</dt>
                  <dd class="duration cols-span-2">{build.duration}</dd>
                </dl>
                <div class="card-actions justify-end">
                  <%= if Images.build_ready?(build) do %>
                    <.link
                      class="btn btn-secondary"
                      href={Images.download_url(build)}
                      download
                    >
                      <.icon name="hero-arrow-down-tray" /> Download {Images.download_size(build)}
                    </.link>
                  <% else %>
                    <div class="loading loading-bars loading-xl">being prepared</div>
                  <% end %>
                </div>
              </div>
            </li>
          </ol>
        </section>

        <section class="card card-border col-span-2">
          <div class="card-body">
            <h3 class="card-title">
              <.icon name="hero-wrench-screwdriver" class="size-6" /> Installation
            </h3>

            <div class="collapse collapse-arrow bg-base-100 border border-base-300">
              <input
                id="sd-gui"
                type="radio"
                name="installation"
                phx-click="open-doc"
                phx-value-section="sd-gui"
                checked={@doc_section == "sd-gui"}
              />
              <label for="sd-gui" class="collapse-title font-semibold">
                Writing to an SD card - GUI
              </label>
              <div class="collapse-content flex flex-col gap-3">
                <p>
                  <.link class="link" href="https://www.raspberrypi.com/software/">Raspberry
                    Pi Imager</.link>
                  can install .img.zst files directly. It's available for Windows, Mac and Linux.
                </p>

                <p>
                  Once installed:
                </p>

                <ol class="list-disc list-inside">
                  <li>Choose your Raspberry Pi device</li>
                  <li>Click "Choose OS"</li>
                  <li>Click "Use Custom" at the bottom of the list</li>
                  <li>Choose your downloaded <code>klix.img.zst</code> file</li>
                  <li>Click "Choose Storage" and select your SD card</li>
                  <li>When asked whether to apply OS customisation settings: choose "NO"</li>
                </ol>
              </div>
            </div>

            <div class="collapse collapse-arrow bg-base-100 border border-base-300">
              <input
                id="sd-cli"
                type="radio"
                name="installation"
                phx-click="open-doc"
                phx-value-section="sd-cli"
                checked={@doc_section == "sd-cli"}
              />
              <label for="sd-cli" class="collapse-title font-semibold">
                Writing to an SD card - Mac/Linux command line
              </label>
              <div class="collapse-content flex flex-col gap-3">
                <p>
                  Insert your SD card and find its device name using <code>lsblk</code>
                  or <code>df</code>. We'll assume it's <code>/dev/sda</code>.
                </p>
                <p>
                  Then, unpack and copy the image to your device. <code>cp</code> will do this:
                </p>
                <div class="mockup-code w-full">
                  <pre data-prefix="$"><code>unzstd klix.img.zst</code></pre>
                  <pre data-prefix="$"><code>umount /dev/sda</code></pre>
                  <pre data-prefix="$"><code>cp --verbose klix.img /dev/sda</code></pre>
                </div>
                <p>
                  <code>unzstd</code>
                  is available from
                  <.link class="link" href="https://github.com/facebook/zstd/releases">the
                    project's GitHub releases</.link>
                  or from your favourite package manager.
                </p>
              </div>
            </div>

            <div class="collapse collapse-arrow bg-base-100 border border-base-300">
              <input
                id="wifi"
                type="radio"
                name="installation"
                phx-click="open-doc"
                phx-value-section="wifi"
                checked={@doc_section == "wifi"}
              />
              <label for="wifi" class="collapse-title font-semibold">
                Connecting to WiFi
              </label>
              <div class="collapse-content flex flex-col gap-3">
                <p>
                  If you installed KlipperScreen and have a screen connected, use its interface to add a WiFi connection.
                </p>
                <p>
                  If not, you must make your first connection via ethernet cable:
                </p>

                <ol class="list-disc list-inside">
                  <li>Connect your Pi to a router and find its IP in your router's interface.</li>
                  <li>SSH with user "klix" and the SSH key you submitted when creating the image.</li>
                  <li>Once connected, type <code>nmtui</code> to connect to a wireless network.</li>
                  <li>Type <code>sudo reboot</code>,
                    disconnect the cable and verify your machine connects using WiFi on boot</li>
                </ol>
              </div>
            </div>
          </div>
        </section>

        <section class="bg-warning card card-border border-base-300 mb-4">
          <div class="card-body">
            <h3 class="card-title">
              <.icon name="hero-exclamation-triangle" class="size-6" /> Danger zone
            </h3>
            <div class="flex flex-col gap-3">
              <p>
                You can delete this image if you no longer want to see it listed.
              </p>
            </div>
            <div class="card-actions justify-end">
              <button
                id="delete"
                class="btn"
                phx-click="delete"
                data-confirm="Really delete this image?"
              >
                <.icon name="hero-trash" class="size-6" /> Delete image
              </button>
            </div>
          </div>
        </section>
      </div>
    </Layouts.app>
    """
  end

  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  def handle_params(%{"id" => id}, _uri, socket) do
    image = Images.find!(socket.assigns.current_scope, id)

    Images.subscribe(image.id)

    {
      :noreply,
      socket
      |> assign(
        page_title: "#{image.hostname} image",
        doc_section: nil,
        image: with_durations(image, tick_clock())
      )
    }
  end

  def handle_event("open-doc", %{"section" => section}, socket) do
    {:noreply, assign(socket, doc_section: section)}
  end

  def handle_event("delete", _params, socket) do
    {:ok, _image} = Images.soft_delete(socket.assigns.current_scope, socket.assigns.image)

    {:noreply,
     socket
     |> push_navigate(to: ~p"/images")
     |> put_flash(:info, "Image deleted")}
  end

  def handle_info([build_ready: %Images.Build{} = updated_build], socket) do
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

    {
      :noreply,
      update(socket, :image, fn image ->
        with_durations(image, now)
      end)
    }
  end

  defp tick_clock() do
    interval = :timer.seconds(1)
    now = DateTime.utc_now()
    next_tick = now |> DateTime.add(interval, :millisecond)

    Process.send_after(self(), {:tick, next_tick}, interval)

    now
  end

  defp with_durations(image, now) do
    update_in(image.builds, fn builds ->
      Enum.map(builds, fn build ->
        %{build | duration: Images.build_duration(build, now)}
      end)
    end)
  end
end
