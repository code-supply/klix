defmodule Klix.Builder do
  use GenServer, restart: :temporary

  @log_lock_file_creation "warning: creating lock file"
  @log_output_path_ready "[{\"drvPath"

  alias Klix.Images

  import Klix.ToNix

  defmodule State do
    @enforce_keys [
      :build_dir,
      :cmd,
      :uploader,
      :version_retriever
    ]
    defstruct [
      :build,
      :build_dir,
      :cmd,
      :error,
      :output_path,
      :uploader,
      :version_retriever,
      telemetry_meta: %{}
    ]
  end

  def telemetry_events do
    [
      [:builder, :build_log],
      [:builder, :build_started],
      [:builder, :uploading],
      [:builder, :versions_stored]
      | Klix.Scheduler.events_for(:builder)
    ]
  end

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts)
  end

  @impl true
  def init(opts) do
    state =
      struct!(
        State,
        Enum.into(opts, %{
          build_dir: "/tmp/klix-build",
          cmd: ~w(
          nix
          build 
          --json
          --no-link 
          --no-pretty 
          .#packages.aarch64-linux.image
        ) |> Enum.join(" ")
        })
      )

    emit(state, :idle)
    {:ok, state}
  end

  @impl true
  def handle_info(:set_up, state) do
    state = clear_build_data(state)

    case Images.next_build() do
      nil ->
        emit(state, :nothing_to_do)
        {:noreply, state}

      build ->
        :ok =
          state
          |> flake_nix_path()
          |> File.write(to_nix(build.image))

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

  def handle_info({port, {:data, <<@log_lock_file_creation, _rest::binary>> = output}}, state)
      when is_port(port) do
    {:ok, flake_nix} =
      state
      |> flake_nix_path()
      |> File.read()

    {:ok, flake_lock} =
      state
      |> flake_lock_path()
      |> File.read()

    {:ok, build} = Images.set_build_flake_files(state.build, flake_nix, flake_lock)

    emit(state, :build_log, %{content: output})
    {:noreply, %{state | build: build}}
  end

  def handle_info({port, {:data, <<@log_output_path_ready, _rest::binary>> = output}}, state)
      when is_port(port) do
    {:ok, [%{"outputs" => %{"out" => output_path}}]} = JSON.decode(output)
    {:ok, build} = Images.file_ready(state.build, output_path)

    emit(state, :build_log, %{content: output})
    {:noreply, %{state | build: build, output_path: output_path}}
  end

  def handle_info({port, {:data, output}}, state)
      when is_port(port) do
    state =
      case Regex.scan(~r/^error: .*line \d+:.*-source\/(.* No such file or directory)/s, output) do
        [[_full_match, error]] ->
          %{state | error: ~s(Path to config dir incorrect: "#{error}")}

        _ ->
          state
      end

    emit(state, :build_log, %{content: output})
    {:noreply, state}
  end

  def handle_info({port, {:exit_status, 0}}, state) when is_port(port) do
    send(port, {self(), :close})
    {:ok, path} = Images.sd_file_path(state.output_path)

    {:ok, versions} = state.version_retriever.(state.build_dir)
    {:ok, build} = Images.store_versions(state.build, versions)

    emit(state, :versions_stored)

    emit(state, :uploading)

    {:ok, _build} =
      case state.uploader.(
             path,
             "builds/#{build.id}.img.zst"
           ) do
        :ok ->
          Images.build_completed(build)

        {:error, msg} ->
          Images.build_failed(build, msg)
      end

    emit(state, :run_complete)
    {:noreply, state}
  end

  def handle_info({port, {:exit_status, code}}, state) when is_port(port) do
    send(port, {self(), :close})

    {:ok, _build} =
      Images.build_failed(state.build, state.error || "nonzero exit code: #{code}")

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

  defp clear_build_data(state) do
    %{state | build: nil, error: nil, telemetry_meta: %{}, output_path: nil}
  end

  defp flake_nix_path(state), do: Path.join(state.build_dir, "flake.nix")
  defp flake_lock_path(state), do: Path.join(state.build_dir, "flake.lock")
end
