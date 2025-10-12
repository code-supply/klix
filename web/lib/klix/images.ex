defmodule Klix.Images do
  alias __MODULE__.{Build, Image}
  alias ExAws.S3
  alias Klix.Accounts.Scope
  alias Klix.Repo

  import Klix.ToNix

  def versions(%Image{}, %Build{versions: nil}), do: []

  def versions(%Image{} = image, %Build{} = build) do
    build.versions
    |> Map.from_struct()
    |> Enum.reject(fn {k, _v} ->
      k == :id or disabled?(image, k)
    end)
    |> Enum.map(fn
      {name, nil} ->
        {name, nil}

      {name, <<version::binary-size(40)>>} ->
        {name, String.slice(version, 0..6)}

      {name, version} ->
        {name, String.replace(version, ~r/-stable_.*/, "")}
    end)
    |> Enum.into([])
  end

  def soft_delete(%Scope{} = scope, %Image{} = image) do
    if scope.user.id == image.user_id do
      Ecto.Changeset.change(image, deleted_at: DateTime.utc_now(:second))
      |> Repo.update()
    else
      {:error, :invalid_scope}
    end
  end

  def retrieve_versions(dir) do
    case System.cmd(
           "nix",
           ~w(eval --json .#versions),
           cd: dir,
           stderr_to_stdout: true
         ) do
      {versions, 0} ->
        [_junk, doc] = String.split(versions, "{", parts: 2)
        JSON.decode("{" <> doc)

      {_, exit_status} ->
        {:error, :nix_eval_failed, exit_status}
    end
  end

  def s3_uploader(source, destination) do
    {:ok, _} =
      source
      |> S3.Upload.stream_file()
      |> S3.upload(Application.fetch_env!(:klix, :build_bucket), destination)
      |> ExAws.request()

    :ok
  rescue
    File.Error -> {:error, :source_not_present}
  end

  def subscribe(image_id) when is_integer(image_id) do
    Phoenix.PubSub.subscribe(Klix.PubSub, "image:#{image_id}")
  end

  def broadcast(image_id, message) when is_integer(image_id) do
    Phoenix.PubSub.broadcast(Klix.PubSub, "image:#{image_id}", message)
  end

  def list() do
    Image.Query.base()
    |> Repo.all()
  end

  def list(%Scope{} = scope) do
    Image.Query.for_scope(scope)
    |> Repo.all()
    |> Repo.preload(:builds)
  end

  def find(uuid) when is_binary(uuid) do
    Image.Query.base()
    |> Repo.get_by(uri_id: uuid)
  end

  def find!(uuid) when is_binary(uuid) do
    Image.Query.base()
    |> Repo.get_by!(uri_id: uuid)
  end

  def find!(%Scope{} = scope, id) do
    Image.Query.for_scope(scope)
    |> Repo.get!(id)
    |> Repo.preload(:builds)
  end

  def find_build(%Scope{} = scope, image_id, build_id) do
    Build.Query.for_scope(scope)
    |> Repo.get_by(image_id: image_id, id: build_id)
  end

  def create(%Scope{} = scope, attrs) do
    %Image{user: scope.user, builds: [[]]}
    |> Image.changeset(attrs)
    |> Repo.insert()
  end

  def snapshot(%Image{} = image) do
    flake_nix = to_nix(image)

    with {:ok, snapshot_attrs, tarball} <- Klix.Snapshotter.snapshot(flake_nix),
         snapshot <- Ecto.build_assoc(image, :snapshots, snapshot_attrs),
         {:ok, snapshot} <- Repo.insert(snapshot) do
      {:ok, snapshot, tarball}
    else
      otherwise -> otherwise
    end
  end

  def next_build do
    Build.Query.next() |> Repo.one()
  end

  def download_size(%Build{byte_size: nil}), do: ""

  def download_size(%Build{} = build) do
    "#{Float.round(build.byte_size / 1_000_000_000, 2)} GB"
  end

  def download_url(%Build{} = build) do
    {:ok, url} =
      ExAws.Config.new(:s3)
      |> S3.presigned_url(
        :get,
        Application.fetch_env!(:klix, :build_bucket),
        "builds/#{build.id}.img.zst",
        expires_in: :timer.minutes(10),
        query_params: %{"response-content-disposition" => "attachment; filename=\"klix.img.zst\""}
      )

    url
  end

  def plugins(%Image{} = image) do
    [
      plugin_kamp_enabled: "KAMP",
      plugin_shaketune_enabled: "Shaketune",
      plugin_z_calibration_enabled: "Z Calibration"
    ]
    |> Enum.filter(fn {flag, _name} ->
      Map.fetch!(image, flag)
    end)
  end

  def set_host_public_key(%Image{} = image, public_key) do
    image
    |> Ecto.Changeset.change(host_public_key: public_key)
    |> Repo.update()
  end

  def set_uri_id(%Image{} = image, uri_id) do
    image
    |> Ecto.Changeset.change(uri_id: uri_id)
    |> Repo.update()
  end

  def set_build_flake_files(%Build{} = build, flake_nix, flake_lock) do
    build
    |> Ecto.Changeset.change(flake_nix: flake_nix, flake_lock: flake_lock)
    |> Repo.update()
  end

  def file_ready(%Build{} = build, output_path) do
    with {:ok, path} <- sd_file_path(output_path),
         {:ok, stat} = File.stat(path) do
      build
      |> Ecto.Changeset.change(byte_size: stat.size)
      |> Repo.update()
    end
  end

  def store_versions(%Build{} = build, versions) do
    build
    |> Ecto.Changeset.cast(%{versions: versions}, [])
    |> Ecto.Changeset.cast_embed(:versions)
    |> Repo.update()
  end

  def store_versions(%Scope{image: image}, versions) do
    image
    |> Image.current_versions_changeset(versions)
    |> Repo.update()
  end

  def build_completed(%Build{} = build) do
    build
    |> Build.success_changeset()
    |> Repo.update()
    |> tap(&broadcast_ready/1)
  end

  def build_failed(%Build{} = build, error) do
    build
    |> Build.failure_changeset(error)
    |> Repo.update()
    |> tap(&broadcast_ready/1)
  end

  def build_ready?(%Build{} = build), do: !!build.completed_at

  def build_duration(build, now \\ DateTime.utc_now())

  def build_duration(%Build{completed_at: nil} = build, now) do
    now
    |> DateTime.diff(build.inserted_at)
    |> Time.from_seconds_after_midnight()
  end

  def build_duration(%Build{} = build, _now) do
    build.completed_at
    |> DateTime.diff(build.inserted_at)
    |> Time.from_seconds_after_midnight()
  end

  def sd_file_path(output_path) do
    sd_dir = Path.join(output_path, "sd-image")

    case File.ls(sd_dir) do
      {:ok, [sd_file]} ->
        {:ok, Path.join(sd_dir, sd_file)}

      _ ->
        {:error, :sd_dir_not_found}
    end
  end

  defp disabled?(%Image{} = image, key) when key in [:z_calibration, :shaketune, :kamp] do
    !Map.get(image, String.to_existing_atom("plugin_#{key}_enabled"), true)
  end

  defp disabled?(%Image{} = image, :klipperscreen) do
    !Map.get(image, :klipperscreen_enabled, true)
  end

  defp disabled?(%Image{}, _key), do: false

  defp broadcast_ready({:ok, build}) do
    broadcast(build.image_id, build_ready: build)
  end
end
