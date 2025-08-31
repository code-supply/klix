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
  def handle_info(:set_up, state) do
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

  def handle_info(:run, state) do
    port =
      Port.open(
        {:spawn, "nix build --print-build-logs .#packages.aarch64-linux.image"},
        [:binary, cd: state.build_dir]
      )

    emit(:build_started, %{port: port})
    {:noreply, state}
  end

  def handle_info({port, {:data, output}}, state) when is_port(port) do
    IO.puts("LOG: #{output}")
    {:noreply, state}
  end

  defp emit(name, measurements \\ %{}) do
    :telemetry.execute([:builder, name], measurements, %{})
  end
end
