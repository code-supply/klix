defmodule KlixWeb.ImageLive do
  use KlixWeb, :live_view

  alias Phoenix.LiveView.AsyncResult

  def render(assigns) do
    ~H"""
    <div class="mt-6 hero">
      <div class="hero-content text-center bg-info rounded">
        <div>
          <h2 class="mb-4 text-3xl">"{@image.hostname}" image</h2>
          <p>
            Your image is being prepared.
          </p>
          <.async_result :let={build} assign={@build}>
            <:loading>
              <div class="mt-4 loading loading-bars loading-xl" />
            </:loading>
            <.link id="download" href={~p"/images/#{@image.id}/builds/#{build.id}/content"} download>
              Download
            </.link>
          </.async_result>
        </div>
      </div>
    </div>
    """
  end

  def mount(%{"id" => id}, _session, socket) do
    image = Klix.Images.find!(id)
    Klix.Images.subscribe(image.id)

    {
      :ok,
      socket
      |> assign(
        page_title: "#{image.hostname} image",
        image: image,
        build: AsyncResult.loading()
      )
    }
  end

  def handle_info([build_ready: build], socket) do
    {:noreply, assign(socket, :build, AsyncResult.ok(build))}
  end
end
