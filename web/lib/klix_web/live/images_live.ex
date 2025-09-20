defmodule KlixWeb.ImagesLive do
  use KlixWeb, :live_view

  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <.header>Your Images</.header>
      <ul id="images" class="md:flex flex-wrap gap-5">
        <li
          :for={image <- @images}
          class="mb-4 py-4 pr-4 rounded-xl bg-neutral text-neutral-content w-full md:w-48/100"
        >
          <h2 class="pl-6 pb-5 font-bold text-2xl">{image.hostname}</h2>
          <div class="flex gap-6">
            <figure class="flex-none w-20 px-6">
              <svg
                class="fill-accent w-20"
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
            <div class="pl-5 flex-grow">
              <dl class="grid grid-cols-3 gap-3">
                <dt class="font-bold text-right">Created</dt>
                <dd class="col-span-2">
                  {image.inserted_at
                  |> DateTime.shift_zone!(image.timezone, Tzdata.TimeZoneDatabase)
                  |> Calendar.strftime("%x %X %p")}
                </dd>
                <dt class="font-bold text-right">Timezone</dt>
                <dd class="col-span-2">{image.timezone}</dd>
                <dt class="font-bold text-right">Builds</dt>
                <dd class="col-span-2">{length(image.builds)}</dd>
              </dl>

              <div class="text-right">
                <.link class="btn btn-primary btn-lg font-bold" navigate={~p"/images/#{image.id}"}>
                  Details <.icon name="hero-arrow-right" class="size-6 shrink-0" />
                </.link>
              </div>
            </div>
          </div>
        </li>
      </ul>
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
