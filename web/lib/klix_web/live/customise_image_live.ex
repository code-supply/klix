defmodule KlixWeb.CustomiseImageLive do
  use KlixWeb, :live_view

  import KlixWeb.CoreComponents

  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <h2 class="mt-6 mb-4 text-3xl">Customise your image</h2>

      <.form for={@image} id="image" phx-submit="download" class="grid gap-3">
        <fieldset class="fieldset bg-base-200 border-base-300 rounded-box border p-4">
          <legend class="fieldset-legend">Base OS Options</legend>

          <.input label="Hostname" placeholder="printy-mc-printface" field={@image[:hostname]} />
          <.input
            label="Time Zone"
            placeholder="Europe/London"
            field={@image[:timezone]}
            type="select"
            options={Tzdata.zone_list()}
          />
          <.input label="Public SSH key" field={@image[:public_key]} type="textarea" />
          <.input
            label="Enable KlipperScreen"
            field={@image[:klipperscreen_enabled]}
            type="checkbox"
          />
        </fieldset>

        <fieldset class="fieldset bg-base-200 border-base-300 rounded-box border p-4">
          <legend class="fieldset-legend">Plugins</legend>

          <.input label="KAMP" field={@image[:plugin_kamp_enabled]} type="checkbox" />
          <.input label="Shaketune" field={@image[:plugin_shaketune_enabled]} type="checkbox" />
          <.input
            label="Z Calibration"
            field={@image[:plugin_z_calibration_enabled]}
            type="checkbox"
          />
        </fieldset>

        <.inputs_for :let={klipper_config} field={@image[:klipper_config]}>
          <fieldset class="fieldset bg-base-200 border-base-300 rounded-box border p-4">
            <legend class="fieldset-legend">Klipper Config Source</legend>

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

        <div class="col-span-2">
          <button id="download" class="btn btn-primary float-right">
            <.icon name="hero-arrow-down-tray" /> Download Raspberry Pi Image
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
    case Klix.Images.create(image_params) do
      {:ok, image} ->
        {:noreply, push_navigate(socket, to: ~p"/images/#{image.id}")}

      {:error, changeset} ->
        {:noreply, assign(socket, :image, to_form(changeset))}
    end
  end
end
