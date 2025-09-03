defmodule Klix.Builder do
  use GenServer

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts)
  end

  @impl true
  def init(opts) do
    state =
      Enum.into(opts, %{
        build_dir: "/tmp/klix-build",
        cmd: "nix build --print-build-logs .#packages.aarch64-linux.image",
        telemetry_meta: %{}
      })

    emit(state, :idle)
    {:ok, state}
  end

  @impl true
  def handle_info(:set_up, state) do
    case Klix.Images.next_build() do
      nil ->
        state = %{state | telemetry_meta: %{}}
        emit(state, :no_builds)
        {:noreply, state}

      build ->
        :ok =
          state.build_dir
          |> Path.join("flake.nix")
          |> File.write(Klix.Images.to_flake(build.image))

        state = %{
          state
          | telemetry_meta: %{
              image_id: build.image_id,
              build_id: build.id
            }
        }

        emit(state, :build_setup_complete)
        {:noreply, state}
    end
  end

  def handle_info(:run, state) do
    port =
      Port.open(
        {:spawn, state.cmd},
        [
          :binary,
          :stderr_to_stdout,
          :exit_status,
          cd: state.build_dir
        ]
      )

    emit(state, :build_started, %{port: port})
    {:noreply, state}
  end

  def handle_info({port, {:data, output}}, state) when is_port(port) do
    emit(state, :build_log, %{content: output})
    {:noreply, state}
  end

  def handle_info({port, {:exit_status, 0}}, state) when is_port(port) do
    send(port, {self(), :close})
    emit(state, :build_completed)
    {:noreply, state}
  end

  def handle_info({port, :closed}, state) when is_port(port) do
    {:noreply, state}
  end

  defp emit(state, name, measurements \\ %{}) do
    :telemetry.execute(
      [:builder, name],
      measurements,
      Map.put(state.telemetry_meta, :pid, self())
    )
  end
end
