defmodule Klix.Snapshotter do
  use GenServer

  alias Klix.Images.Snapshot

  def start_link(opts) do
    server_opts = Keyword.take(opts, [:name])
    GenServer.start_link(__MODULE__, opts, server_opts)
  end

  def snapshot(flake_nix) do
    GenServer.call(__MODULE__, {:snapshot, flake_nix}, :timer.minutes(5))
  end

  @impl true
  def init(opts), do: {:ok, Enum.into(opts, %{snapshot_dir: "/tmp/klix-snapshot"})}

  @impl true
  def handle_call({:snapshot, flake_nix}, _from, state) do
    File.mkdir_p!(state.snapshot_dir)
    File.write!("#{state.snapshot_dir}/flake.nix", flake_nix)

    {_, 0} = cmd(state, ~w(rm -f flake.lock config.tar.gz))

    case cmd(state, ~w(nix flake lock)) do
      {_, 0} ->
        snapshot = %Snapshot{
          flake_nix: flake_nix,
          flake_lock: File.read!("#{state.snapshot_dir}/flake.lock")
        }

        tarball_path = ~c"#{state.snapshot_dir}/config.tar.gz"

        :ok =
          :erl_tar.create(
            tarball_path,
            [
              {~c"flake.nix", ~c"#{state.snapshot_dir}/flake.nix"},
              {~c"flake.lock", ~c"#{state.snapshot_dir}/flake.lock"}
            ],
            [:compressed]
          )

        {:reply, {:ok, snapshot, File.read!(tarball_path)}, state}

      output ->
        {:reply, {:error, :error_updating_lock_file, output}, state}
    end
  end

  defp cmd(state, [cmd | args]) do
    System.cmd(cmd, args, cd: state.snapshot_dir, stderr_to_stdout: true)
  end
end
