defmodule KlixWeb.ImageLive do
  use KlixWeb, :live_view

  def render(assigns) do
    ~H"""
    <div class="mt-6 hero">
      <div class="hero-content text-center bg-info rounded">
        <div>
          <h2 class="mb-4 text-3xl">"{@image.hostname}" image</h2>
          <p>
            Your image is being prepared.
          </p>
          <div class="mt-4 loading loading-bars loading-xl" />
        </div>
      </div>
    </div>
    """
  end

  def mount(%{"id" => id}, _session, socket) do
    image = Klix.Images.find!(id)
    {:ok, assign(socket, page_title: "#{image.hostname} image", image: image)}
  end
end
