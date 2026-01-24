defmodule KlixWeb.ManageImageLive do
  use KlixWeb, :live_view

  alias Klix.Images

  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <.header>
        <div class="flex items-center">
          <span class="grow">
            {@image.hostname}
          </span>

          <button
            :if={@current_scope}
            id="rebuild"
            class="btn btn-neutral"
            phx-click="rebuild"
            disabled={Images.building?(@image)}
          >
            <.icon name="hero-arrow-path" class="size-6" /> Rebuild
          </button>
        </div>

        <:subtitle>
          <div class="breadcrumbs text-sm">
            <ol>
              <li>
                <.link class="link" navigate={~p"/"}>Home</.link>
              </li>
              <li>
                <.link class="link" href={~p"/images"}>Your Images</.link>
              </li>
              <li>{@image.hostname}</li>
            </ol>
          </div>
        </:subtitle>
      </.header>

      <div class="md:grid md:grid-cols-2 gap-4">
        <section id="printer-details">
          <div class="bg-base-100 card card-border border-base-300 mb-4 printer">
            <div class="card-body">
              <h3 class="card-title">
                <.icon name="hero-tag" class="size-6" /> Printer details
              </h3>
              <dl class="grid grid-cols-2 gap-2 pt-1">
                <dt class="font-bold">Machine type</dt>
                <dd>
                  {Images.friendly_machine_name(@image)}
                </dd>

                <dt class="font-bold">Hostname</dt>
                <dd>{@image.hostname}</dd>

                <dt class="font-bold">Time zone</dt>
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
                  <p :if={@image.klipper_config_mutable}>Edit on machine</p>
                  <.link
                    :if={@image.klipper_config}
                    class="badge"
                    href={"https://#{@image.klipper_config.type}.com/#{@image.klipper_config.owner}/#{@image.klipper_config.repo}/tree/main/#{@image.klipper_config.path}"}
                  >
                    {Images.KlipperConfig.type_name(@image.klipper_config)}
                  </.link>
                </dd>

                <dt class="font-bold">Last <code>klix-update</code></dt>
                <dd class="klix-updated">
                  {format_datetime(@image.current_versions_updated_at, blank: "never")}
                </dd>
              </dl>

              <.software_versions
                :if={!Enum.empty?(@current_image_versions)}
                title="Current software versions"
                versions={@current_image_versions}
              />
            </div>
          </div>
        </section>

        <section>
          <ol id="builds" class="flex flex-col gap-y-4">
            <li
              :for={{build, idx} <- @image.builds |> Enum.with_index() |> Enum.reverse()}
              id={["build-", to_string(build.id)]}
              class="bg-base-100 card card-border border-base-300 card-md"
            >
              <div class="card-body">
                <h3 class="card-title">
                  <.icon name="hero-cube" class="size-6" /> Build {"##{idx + 1}"}
                </h3>
                <dl class="grid grid-cols-3">
                  <dt class="font-bold">Started</dt>
                  <dd class="col-span-2">{build.inserted_at |> format_datetime()}</dd>
                  <dt :if={Images.build_ready?(build)} class="font-bold">Completed</dt>
                  <dd :if={Images.build_ready?(build)} class="col-span-2">
                    {build.completed_at |> format_datetime()}
                  </dd>
                  <dt class="font-bold">Duration</dt>
                  <dd class="duration col-span-2">{build.duration}</dd>
                </dl>

                <div class="card-actions grid grid-cols-3 build">
                  <%= cond do %>
                    <% Images.build_failed?(build) -> %>
                      <div role="alert" class="col-span-3 alert alert-error">
                        <.icon name="hero-face-frown" class="size-8" />
                        <div>
                          <h3 class="font-bold">Image build failure</h3>
                          <p>{build.error}</p>
                          <p>
                            Please
                            <.link class="link" href="mailto:tech@code.supply">get in touch</.link>
                            to resolve this.
                          </p>
                        </div>
                      </div>
                    <% Images.build_ready?(build) -> %>
                      <.software_versions
                        title="Software versions"
                        versions={Images.versions(build.versions)}
                      />

                      <.link
                        class="col-start-2 col-span-2 btn btn-secondary download"
                        href={~p"/images/#{@image.id}/builds/#{build.id}"}
                        target="_blank"
                      >
                        <.icon name="hero-arrow-down-tray" /> Download {Images.download_size(build)}
                      </.link>
                    <% true -> %>
                      <p class="col-span-2">
                        Download link will appear here when ready.
                      </p>
                      <div class="w-full text-right">
                        <div class="loading loading-bars loading-xl">
                          being prepared
                        </div>
                      </div>
                  <% end %>
                </div>
              </div>
            </li>
          </ol>
        </section>

        <section class="card card-border col-span-2">
          <div class="card-body">
            <h3 class="card-title">
              <.icon name="hero-wrench-screwdriver" class="size-6" /> Getting started
            </h3>

            <div class="collapse collapse-arrow help-accordion">
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
              <div class="collapse-content help-accordion-content">
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

            <div class="collapse collapse-arrow help-accordion">
              <input
                id="sd-cli"
                type="radio"
                name="installation"
                phx-click="open-doc"
                phx-value-section="sd-cli"
                checked={@doc_section == "sd-cli"}
              />
              <label for="sd-cli" class="collapse-title font-semibold">
                Writing to an SD card - Linux command line
              </label>
              <div class="collapse-content help-accordion-content">
                <p>
                  Insert your SD card and find its device name(s) using <code>lsblk</code>.
                  In the following example, we see two
                  partitions, <code>/dev/sda1</code>
                  and <code>/dev/sda2</code>
                  on a device called <code>/dev/sda</code>.
                </p>
                <p>
                  You can tell those two partitions are mounted, because they have MOUNTPOINTS.
                </p>
                <div class="mockup-code w-full">
                  <pre data-prefix="$"><code>lsblk</code></pre>
                  <pre><code>NAME                              MAJ:MIN RM   SIZE RO TYPE  MOUNTPOINTS
      sda                                 8:0    1 116.5G  0 disk
      ├─sda1                              8:1    1    30M  0 part  /run/media/andrew/FIRMWARE
      └─sda2                              8:2    1   5.8G  0 part  /run/media/andrew/NIXOS_SD
      nvme0n1                           259:0    0 931.5G  0 disk
      ├─nvme0n1p1                       259:1    0   512M  0 part  /boot/efi
      ├─nvme0n1p2                       259:2    0 922.2G  0 part
      │ └─luks-73dc2827-b296-40a3-941d-53424502edb7
      │                                 254:1    0 922.2G  0 crypt /nix/store
      │                                                            /
      └─nvme0n1p3                       259:3    0   8.8G  0 part
        └─luks-26861216-bdc0-4196-a13f-1d9b8caaebfe
                                        254:0    0   8.8G  0 crypt [SWAP]</code></pre>
                </div>
                <p>
                  We need to unmount the filesystems, then copy the image to your device:
                </p>
                <div class="mockup-code w-full">
                  <pre data-prefix="$"><code>umount /dev/sda1 /dev/sda2</code></pre>
                  <pre data-prefix="$"><code>zstdcat klix.img.zst > /dev/sda</code></pre>
                </div>
                <p>
                  <code>zstdcat</code>
                  is available from
                  <.link class="link" href="https://github.com/facebook/zstd/releases">the
                    project's GitHub releases</.link>
                  or from your favourite package manager.
                </p>
                <p>
                  Once <code>cp</code> completes (it takes several minutes), you can
                  eject your card and put it into your Raspberry Pi for its
                  first boot.
                </p>
              </div>
            </div>

            <div class="collapse collapse-arrow help-accordion">
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
              <div class="collapse-content help-accordion-content">
                <p>
                  If you installed KlipperScreen and have a screen connected, use its interface to add a WiFi connection.
                </p>
                <p>
                  If not, make your first connection via ethernet cable:
                </p>

                <ol class="list-disc list-inside">
                  <li>Connect your Pi to a router and find its IP in your router's interface.</li>
                  <li>SSH with user "klix" and the SSH key you submitted when creating the image.</li>
                  <li>
                    Once connected, type the following to connect to a wireless network.
                    <div class="mockup-code w-full">
                      <pre data-prefix="$"><code>nmtui</code></pre>
                    </div>
                  </li>
                  <li>
                    Optionally, disconnect your cable and verify that your machine connects on boot with:
                    <div class="mockup-code w-full">
                      <pre data-prefix="$"><code>sudo reboot</code></pre>
                    </div>
                  </li>
                </ol>
              </div>
            </div>

            <div class="collapse collapse-arrow help-accordion">
              <input
                id="updating"
                type="radio"
                name="installation"
                phx-click="open-doc"
                phx-value-section="updating"
                checked={@doc_section == "updating"}
              />
              <label for="updating" class="collapse-title font-semibold">
                Updating your system
              </label>
              <div class="collapse-content help-accordion-content">
                <p>
                  SSH into your printer and type:
                </p>
                <div class="mockup-code w-full">
                  <pre data-prefix="$"><code>sudo klix-update</code></pre>
                </div>
                <p>
                  This will only pull changes that we've tested and released to our users.
                  Versions of software might change.
                </p>
              </div>
            </div>
          </div>
        </section>

        <section
          :if={@current_scope}
          class="bg-warning text-warning-content card card-border border-base-300 mb-4 col-start-2"
        >
          <div class="card-body">
            <h3 class="card-title">
              <.icon name="hero-exclamation-triangle" class="size-6" /> Danger zone
            </h3>
            <div class="flex flex-col gap-3">
              <p>
                You can delete this image if you no longer use it in the printer, or no longer want to manage the system through Klix.
              </p>
              <p>
                Doing so will disable Klix updates.
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
        image: with_durations(image, tick_clock()),
        current_image_versions: Images.versions(image.current_versions)
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

  def handle_event("rebuild", _params, %{assigns: %{image: image, current_scope: scope}} = socket) do
    {:ok, build} = Images.build(scope, image)

    {
      :noreply,
      assign(
        socket,
        :image,
        update_in(image.builds, fn builds -> builds ++ [build] end)
      )
    }
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

  attr :title, :string
  attr :versions, :list

  defp software_versions(assigns) do
    ~H"""
    <div class="col-span-3 collapse collapse-arrow bg-base-300">
      <input type="checkbox" />
      <h4 class="py-2 collapse-title">{@title}</h4>
      <dl class="collapse-content grid grid-cols-2 versions">
        <.version
          :for={{package, version} <- @versions}
          package={package}
          version={version}
        />
      </dl>
    </div>
    """
  end

  attr :package, :string
  attr :version, :string

  defp version(assigns) do
    ~H"""
    <dt>{@package}</dt>
    <dd class={"text-right #{@package}"}>{@version}</dd>
    """
  end

  defp tick_clock do
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
