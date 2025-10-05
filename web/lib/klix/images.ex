defmodule Klix.Images do
  alias __MODULE__.{Build, Image}
  alias ExAws.S3
  alias Klix.Accounts.Scope
  alias Klix.Repo

  import Klix.ToNix

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
    Image
    |> Repo.get_by(uri_id: uuid)
  end

  def find!(uuid) when is_binary(uuid) do
    Image
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
    |> Klix.Images.Image.changeset(attrs)
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
    Klix.Images.Build.Query.next() |> Repo.one()
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
        expires_in: :timer.minutes(10)
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

  defp broadcast_ready({:ok, build}) do
    broadcast(build.image_id, build_ready: build)
  end
end
