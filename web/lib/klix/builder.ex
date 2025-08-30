defmodule Klix.Builder do
  use GenServer

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts)
  end

  @impl true
  def init(opts) do
    state = %{scheduler: Keyword.fetch!(opts, :scheduler)}
    emit(:idle)
    {:ok, state}
  end

  @impl true
  def handle_info(:run, state) do
    case Klix.Images.next_build() do
      nil ->
        emit(:no_builds)

      build ->
        emit(:build_found, %{image_id: build.image_id})
    end

    {:noreply, state}
  end

  defp emit(name, measurements \\ %{}) do
    :telemetry.execute([:builder, name], measurements, %{})
  end
end
