defmodule Klix.Builder do
  use GenServer

  def telemetry_events do
    [
      [:builder, :build_log],
      [:builder, :build_started]
      | Klix.Scheduler.events_for(:builder)
    ]
  end

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts)
  end

  @impl true
  def init(opts) do
    state =
      Enum.into(opts, %{
        build: nil,
        build_dir: "/tmp/klix-build",
        cmd: ~w(
          nix
          build 
          --log-format internal-json
          --verbose
          --no-link 
          --no-pretty 
          --cores 1
          .#packages.aarch64-linux.image
        ) |> Enum.join(" "),
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
        emit(state, :nothing_to_do)
        {:noreply, state}

      build ->
        :ok =
          state
          |> flake_nix_path()
          |> File.write(Klix.Images.to_flake(build.image))

        state
        |> flake_lock_path()
        |> File.rm()

        state = %{
          state
          | build: build,
            telemetry_meta: %{
              image_id: build.image_id,
              build_id: build.id,
              port: nil
            }
        }

        emit(state, :setup_complete)
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

    state = put_in(state.telemetry_meta.port, port)
    emit(state, :build_started)
    {:noreply, state}
  end

  def handle_info(
        {port, {:data, <<"warning: creating lock file", _rest::binary>> = output}},
        state
      )
      when is_port(port) do
    {:ok, flake_nix} =
      state
      |> flake_nix_path()
      |> File.read()

    {:ok, flake_lock} =
      state
      |> flake_lock_path()
      |> File.read()

    {:ok, build} = Klix.Images.set_build_flake_files(state.build, flake_nix, flake_lock)

    emit(state, :build_log, %{content: output})
    {:noreply, %{state | build: build}}
  end

  def handle_info(
        {port, {:data, <<"[{\"drvPath", _rest::binary>> = output}},
        state
      )
      when is_port(port) do
    {:ok, [%{"outputs" => %{"out" => output_path}}]} = JSON.decode(output)
    {:ok, build} = Klix.Images.set_build_output_path(state.build, output_path)

    emit(state, :build_log, %{content: output})
    {:noreply, %{state | build: build}}
  end

  def handle_info({port, {:data, output}}, state) when is_port(port) do
    emit(state, :build_log, %{content: output})
    {:noreply, state}
  end

  def handle_info({port, {:exit_status, 0}}, state) when is_port(port) do
    send(port, {self(), :close})
    emit(state, :run_complete)
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

  defp flake_nix_path(state), do: Path.join(state.build_dir, "flake.nix")
  defp flake_lock_path(state), do: Path.join(state.build_dir, "flake.lock")
end
