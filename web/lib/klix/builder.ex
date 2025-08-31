defmodule Klix.Builder do
  use GenServer

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts)
  end

  @impl true
  def init(opts) do
    state = Enum.into(opts, %{})
    emit(:idle)
    {:ok, state}
  end

  @impl true
  def handle_info(:run, state) do
    case Klix.Images.next_build() do
      nil ->
        emit(:no_builds)

      build ->
        :ok =
          state.build_dir
          |> Path.join("flake.nix")
          |> File.write(Klix.Images.to_flake(build.image))

        emit(:build_setup_complete, %{image_id: build.image_id})
    end

    {:noreply, state}
  end

  defp emit(name, measurements \\ %{}) do
    :telemetry.execute([:builder, name], measurements, %{})
  end
end
