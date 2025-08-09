defmodule KlixWeb.CustomImageLive do
  use Phoenix.LiveView

  import KlixWeb.CoreComponents

  def render(assigns) do
    ~H"""
    <div class="hero bg-base-200 min-h-screen">
      <div class="hero-content">
        <div class="max-w-md">
          <h1 class="text-5xl font-bold">Klix</h1>
          <p class="py-6">An operating system for 3D printers.</p>
          <.form for={@image} phx-submit="download">
            <fieldset class="fieldset bg-base-200 border-base-300 rounded-box w-xs border p-4">
              <legend class="fieldset-legend">Options</legend>

              <.input label="Hostname" placeholder="Printy Mc. Printface" field={@image[:hostname]} />

              <button id="download" class="btn btn-primary" phx-click="download">Download</button>
            </fieldset>
          </.form>
        </div>
      </div>
    </div>
    """
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
