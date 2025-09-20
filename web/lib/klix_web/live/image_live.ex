defmodule KlixWeb.ImageLive do
  use KlixWeb, :live_view

  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <.header>{@image.hostname}</.header>

      <div class="hero">
        <div class="hero-content text-center">
          <div>
            <section class="mt-9 bg-base-300 text-left p-3 rounded-xl">
              <h2 class="text-2xl pb-4">Builds</h2>
              <table id="builds">
                <thead>
                  <tr>
                    <th class="py-2 px-4">Started</th>
                    <th class="py-2 px-4">Completed</th>
                    <th class="py-2 px-4">Duration (inc. queue)</th>
                    <th class="py-2 px-4"></th>
                  </tr>
                </thead>
                <tbody>
                  <tr :for={build <- @image.builds}>
                    <td class="p-4">{build.inserted_at}</td>
                    <td class="p-4">{build.completed_at}</td>
                    <td class="p-4 text-right">{Klix.Images.build_duration(build)}</td>
                    <td class="p-4">
                      <%= if Klix.Images.build_ready?(build) do %>
                        <.link
                          class="btn btn-primary"
                          href={~p"/images/#{@image.id}/builds/#{build.id}/klix.img.zst"}
                          download
                        >
                          Download
                        </.link>
                      <% else %>
                        <div class="loading loading-bars loading-xl">being prepared</div>
                      <% end %>
                    </td>
                  </tr>
                </tbody>
              </table>
            </section>
          </div>
        </div>
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
        image: image,
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

  def handle_info([build_ready: updated_build], socket) do
    import Access

    {
      :noreply,
      update(socket, :image, fn image ->
        put_in(image, [key!(:builds), find(&(&1.id == updated_build.id))], updated_build)
      end)
    }
  end
end
