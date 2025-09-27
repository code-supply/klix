defmodule KlixWeb.CustomiseImageLive do
  use KlixWeb, :live_view

  import KlixWeb.CoreComponents

  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <.header>
        Build New Image
        <:subtitle>
          <div class="breadcrumbs text-sm">
            <ol>
              <li>
                <.link class="link" navigate={~p"/"}>Home</.link>
              </li>
              <li>
                <.link class="link" navigate={~p"/images"}>Your Images</.link>
              </li>
              <li>Build New Image</li>
            </ol>
          </div>
        </:subtitle>
      </.header>

      <.form for={@image} id="image" phx-submit="download" class="flex flex-col gap-10">
        <fieldset class="fieldset bg-base-100 border-base-300 rounded-box border p-4 text-2xl">
          <legend class="fieldset-legend">Base OS Options</legend>

          <div class="flex flex-wrap">
            <div class="w-1/2 pr-2">
              <.input label="Hostname" placeholder="printy-mc-printface" field={@image[:hostname]} />
            </div>
            <div class="w-1/2 pl-2">
              <.input
                label="Time Zone"
                placeholder="Europe/London"
                field={@image[:timezone]}
                type="select"
                options={Tzdata.zone_list()}
              />
            </div>
          </div>
          <.input
            label="Public SSH key"
            field={@image[:public_key]}
            type="textarea"
          />
          <div class="bg-info text-info-content p-4 rounded-xl text-sm flex flex-col gap-3">
            <p>
              An SSH key is a secure way to log in to your printer.
              You will use this key for maintenance.
              If you don't have an SSH key yet, you can <.link
                class="link"
                href="https://www.ssh.com/academy/ssh/keygen"
              >generate one</.link>.
            </p>
            <p>
              <code>ssh-add -L</code> will print your public key if you have an SSH agent running.
            </p>
            <p class="font-bold">
              Be sure to only paste the public key. The filename usually ends with <code>.pub</code>.
            </p>
          </div>
        </fieldset>

        <fieldset class="fieldset bg-base-100 border-base-300 rounded-box border p-4 text-2xl">
          <legend class="fieldset-legend">Extra software and plugins</legend>
          <p class="pb-4">
            <.link class="link" href="https://www.klipper3d.org/">Klipper</.link>,
            <.link class="link" href="https://moonraker.readthedocs.io/en/latest/">Moonraker</.link>
            and <.link class="link" href="https://docs.fluidd.xyz/">Fluidd</.link>
            are included as standard.
          </p>

          <div class="flex flex-wrap gap-6">
            <.input label="KAMP" field={@image[:plugin_kamp_enabled]} type="checkbox" />
            <.input label="Shaketune" field={@image[:plugin_shaketune_enabled]} type="checkbox" />
            <.input
              label="Z Calibration"
              field={@image[:plugin_z_calibration_enabled]}
              type="checkbox"
            />
            <.input label="KlipperScreen" field={@image[:klipperscreen_enabled]} type="checkbox" />
          </div>
        </fieldset>

        <.inputs_for :let={klipper_config} field={@image[:klipper_config]}>
          <fieldset class="fieldset bg-base-100 border-base-300 rounded-box border p-4 text-2xl">
            <legend class="fieldset-legend">Klipper Config Source</legend>

            <p class="bg-info text-info-content p-4 rounded-xl text-sm flex flex-col gap-3">
              Your Klipper config will be pulled from this repo. At present, it must be publically viewable.
            </p>

            <.input
              label="Repo type"
              field={klipper_config[:type]}
              type="select"
              options={Klix.Images.KlipperConfig.type_options()}
            />
            <.input label="Repo owner" field={klipper_config[:owner]} />
            <.input label="Repo name" field={klipper_config[:repo]} />
            <.input label="Path to config dir (optional)" field={klipper_config[:path]} />
          </fieldset>
        </.inputs_for>

        <div class="col-span-2 text-center pt-4">
          <button id="download" class="btn btn-lg btn-primary">
            Build Raspberry Pi Image <.icon name="hero-arrow-right" class="size-6 shrink-0" />
          </button>
        </div>
      </.form>
    </Layouts.app>
    """
  end

  def mount(_params, _session, socket) do
    {:ok, assign(socket, page_title: "Custom 3D Printer OS Image")}
  end

  def handle_params(_unsigned_params, _uri, socket) do
    {
      :noreply,
      assign(socket, :image, %Klix.Images.Image{} |> Ecto.Changeset.change() |> to_form())
    }
  end

  def handle_event("download", %{"image" => image_params}, socket) do
    case Klix.Images.create(socket.assigns.current_scope, image_params) do
      {:ok, image} ->
        {:noreply, push_navigate(socket, to: ~p"/images/#{image.id}")}

      {:error, changeset} ->
        {:noreply, assign(socket, :image, to_form(changeset))}
    end
  end
end
