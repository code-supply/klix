defmodule KlixWeb.CustomImageLive do
  use Phoenix.LiveView

  import KlixWeb.CoreComponents

  def render(assigns) do
    ~H"""
    <div class="hero bg-base-200 min-h-screen">
      <div class="hero-content">
        <div>
          <h1 class="text-5xl font-bold">Klix</h1>
          <h2>Klipper + NixOS</h2>
          <p class="py-6">A parametric operating system for 3D printers.</p>
          <.form for={@image} phx-submit="download" class="grid grid-cols-2 gap-3">
            <fieldset class="fieldset bg-base-200 border-base-300 rounded-box w-xs border p-4">
              <legend class="fieldset-legend">Base OS Options</legend>

              <.input label="Hostname" placeholder="Printy Mc. Printface" field={@image[:hostname]} />
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

            <fieldset class="fieldset bg-base-200 border-base-300 rounded-box w-xs border p-4">
              <legend class="fieldset-legend">Plugins</legend>

              <.input label="KAMP" field={@image[:plugin_kamp_enabled]} type="checkbox" />
              <.input label="Shaketune" field={@image[:plugin_shaketune_enabled]} type="checkbox" />
              <.input
                label="Z Calibration"
                field={@image[:plugin_z_calibration_enabled]}
                type="checkbox"
              />
            </fieldset>

            <div class="col-span-2">
              <button id="download" class="btn btn-primary float-right" phx-click="download">
                <.icon name="hero-arrow-down-tray" /> Download Raspberry Pi Image
              </button>
            </div>
          </.form>
        </div>
      </div>
    </div>
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

  def handle_event(_event, _unsigned_params, socket) do
    {:noreply, socket}
  end
end
