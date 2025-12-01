defmodule KlixWeb.ImagesLive do
  use KlixWeb, :live_view

  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <.header>
        Your Images
        <:subtitle>
          <div class="breadcrumbs text-sm">
            <ol>
              <li>
                <.link class="link" navigate={~p"/"}>Home</.link>
              </li>
              <li>Your Images</li>
            </ol>
          </div>
        </:subtitle>
      </.header>
      <ul id="images" class="md:flex flex-wrap gap-5">
        <li
          :for={image <- @images}
          class="card card-side card-border border-base-300 card-md bg-base-100 mb-3"
        >
          <figure class="w-24 pl-5">
            <svg
              class="fill-accent"
              version="1.1"
              xmlns="http://www.w3.org/2000/svg"
              xmlns:xlink="http://www.w3.org/1999/xlink"
              viewBox="0 0 512 512"
              xml:space="preserve"
            >
              <g>
                <path
                  class="st0"
                  d="M459.772,147.559V34.37c0-18.985-15.393-34.37-34.37-34.37H157.397c-9.112,0-17.854,3.617-24.3,10.07
    L62.291,80.869c-6.446,6.446-10.063,15.188-10.063,24.308v372.461c0,18.976,15.385,34.362,34.362,34.362h338.813
    c18.977,0,34.37-15.386,34.37-34.362v-259.65h-33.541v-70.429H459.772z M299.281,38.438h32.557v77.4h-32.557V38.438z
    M238.905,38.438h32.566v77.4h-32.566V38.438z M178.539,38.438h32.566v77.4h-32.566V38.438z M118.172,63.721h32.566v77.409h-32.566
    V63.721z M388.219,428.162H123.273V382.86h264.947V428.162z M392.205,115.838h-32.566v-77.4h32.566V115.838z"
                />
              </g>
            </svg>
          </figure>
          <div class="card-body">
            <h2 class="card-title">
              {image.hostname}
            </h2>
            <dl class="grid grid-cols-3 gap-2">
              <dt class="font-bold">Created</dt>
              <dd class="col-span-2">
                {image.inserted_at
                |> DateTime.shift_zone!(image.timezone, Tzdata.TimeZoneDatabase)
                |> format_datetime()}
              </dd>
              <dt class="font-bold">Machine type</dt>
              <dd class="col-span-2">{Klix.Images.friendly_machine_name(image)}</dd>
              <dt class="font-bold">Time zone</dt>
              <dd class="col-span-2">{image.timezone}</dd>
              <dt class="font-bold">Builds</dt>
              <dd class="col-span-2">{length(image.builds)}</dd>
            </dl>
            <div class="card-actions justify-end">
              <.link class="btn btn-secondary" navigate={~p"/images/#{image.id}"}>
                Details <.icon name="hero-arrow-right" class="size-6 shrink-0" />
              </.link>
            </div>
          </div>
        </li>
      </ul>

      <div class="text-right pt-6 pr-4">
        <.link id="begin" navigate={~p"/images/new"} class="btn btn-lg btn-primary">
          Build New Image <.icon name="hero-arrow-right" class="size-6 shrink-0" />
        </.link>
      </div>
    </Layouts.app>
    """
  end

  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  def handle_params(%{"id" => id}, _uri, socket) do
    image = Klix.Images.find!(socket.assigns.current_scope, id)

    Klix.Images.subscribe(image.id)

    {
      :noreply,
      socket
      |> assign(
        page_title: "#{image.hostname} image",
        images: Klix.Images.list(socket.assigns.current_scope)
      )
    }
  end

  def handle_params(_params, _uri, socket) do
    {
      :noreply,
      socket
      |> assign(
        page_title: "Images",
        images: Klix.Images.list(socket.assigns.current_scope)
      )
    }
  end
end
