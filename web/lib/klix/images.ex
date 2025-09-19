defmodule Klix.Images do
  alias __MODULE__.Build
  alias __MODULE__.Image
  alias Klix.Accounts.Scope

  import Klix.ToNix

  def subscribe(image_id) when is_integer(image_id) do
    Phoenix.PubSub.subscribe(Klix.PubSub, "image:#{image_id}")
  end

  def broadcast(image_id, message) when is_integer(image_id) do
    Phoenix.PubSub.broadcast(Klix.PubSub, "image:#{image_id}", message)
  end

  def list() do
    Image.Query.base()
    |> Klix.Repo.all()
  end

  def list(%Scope{} = scope) do
    Image.Query.for_scope(scope)
    |> Klix.Repo.all()
    |> Klix.Repo.preload(:builds)
  end

  def find!(%Scope{} = scope, id) do
    Image.Query.for_scope(scope)
    |> Klix.Repo.get!(id)
    |> Klix.Repo.preload(:builds)
  end

  def find_build(%Scope{} = scope, image_id, build_id) do
    Build.Query.for_scope(scope)
    |> Klix.Repo.get_by(image_id: image_id, id: build_id)
  end

  def create(%Scope{} = scope, attrs) do
    %Image{user: scope.user, builds: [[]]}
    |> Klix.Images.Image.changeset(attrs)
    |> Klix.Repo.insert()
  end

  def next_build do
    Klix.Images.Build.Query.next() |> Klix.Repo.one()
  end

  def set_build_flake_files(%Build{} = build, flake_nix, flake_lock) do
    build
    |> Ecto.Changeset.change(flake_nix: flake_nix, flake_lock: flake_lock)
    |> Klix.Repo.update()
  end

  def set_build_output_path(%Build{} = build, output_path) do
    build
    |> Ecto.Changeset.change(output_path: output_path)
    |> Klix.Repo.update()
  end

  def build_completed(%Build{} = build) do
    build
    |> Ecto.Changeset.change(completed_at: DateTime.utc_now(:second))
    |> Klix.Repo.update()
    |> tap(fn {:ok, build} ->
      broadcast(build.image_id, build_ready: build)
    end)
  end

  def build_ready?(%Build{} = build), do: !!build.completed_at

  def sd_file_path(%Build{} = build) do
    sd_dir = Path.join(build.output_path, "sd-image")
    {:ok, [sd_file]} = File.ls(sd_dir)
    Path.join(sd_dir, sd_file)
  end

  def to_flake(%Image{} = image) do
    """
    {
      inputs = {
        nixpkgs.url = "github:NixOS/nixpkgs/e6cb50b7edb109d393856d19b797ba6b6e71a4fc";
        klipperConfig = #{image.klipper_config |> to_nix() |> Klix.indent(from: 1) |> Klix.indent(from: 1)};
        klix = {
          url = "github:code-supply/klix";
          inputs.nixpkgs.follows = "nixpkgs";
        };
      };

      outputs =
        {
          self,
          klipperConfig,
          nixpkgs,
          klix,
        }:
        {
          packages.aarch64-linux.image = self.nixosConfigurations.#{image.hostname}.config.system.build.sdImage;
          nixosConfigurations.#{image.hostname} = nixpkgs.lib.nixosSystem {
            modules = [
              klix.nixosModules.default
              {
                networking.hostName = "#{image.hostname}";
                time.timeZone = "#{image.timezone}";
                system.stateVersion = "25.05";
                users.users.klix.openssh.authorizedKeys.keys = [
                  "#{image.public_key}"
                ];
                services.klix.configDir = "${klipperConfig}/#{image.klipper_config.path}";
                services.klipper = {
                  plugins = {
                    kamp.enable = #{image.plugin_kamp_enabled};
                    shaketune.enable = #{image.plugin_shaketune_enabled};
                    z_calibration.enable = #{image.plugin_z_calibration_enabled};
                  };
                };

                services.klipperscreen.enable = #{image.klipperscreen_enabled};
              }
            ];
          };
        };
    }
    """
  end
end
