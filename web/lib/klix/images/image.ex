defmodule Klix.Images.Image do
  use Ecto.Schema

  @options_for_machine [
    {"Raspberry Pi 4", :raspberry_pi_4},
    {"Raspberry Pi 5", :raspberry_pi_5}
  ]

  schema "images" do
    field :uri_id, Ecto.UUID, autogenerate: true
    field :machine, Ecto.Enum, values: Keyword.values(@options_for_machine)
    field :hostname, :string
    field :timezone, :string, default: "Europe/London"
    field :klipperscreen_enabled, :boolean, default: true
    field :plugin_kamp_enabled, :boolean, default: true
    field :plugin_shaketune_enabled, :boolean, default: true
    field :plugin_z_calibration_enabled, :boolean, default: true
    field :public_key, :string
    field :host_public_key, :binary
    field :current_versions_updated_at, :utc_datetime
    field :deleted_at, :utc_datetime

    embeds_one :current_versions, Klix.Images.Versions
    embeds_one :klipper_config, Klix.Images.KlipperConfig

    belongs_to :user, Klix.Accounts.User

    has_many :builds, Klix.Images.Build
    has_many :snapshots, Klix.Images.Snapshot

    timestamps(type: :utc_datetime)
  end

  def changeset(image, params) do
    import Ecto.Changeset

    image
    |> cast(params, [
      :machine,
      :hostname,
      :klipperscreen_enabled,
      :plugin_kamp_enabled,
      :plugin_shaketune_enabled,
      :plugin_z_calibration_enabled,
      :public_key,
      :timezone
    ])
    |> cast_embed(:klipper_config)
    |> validate_format(:hostname, ~r/^[^-].*$/, message: "must not start with a hyphen")
    |> validate_format(:hostname, ~r/^.*[^-]$/, message: "must not end with a hyphen")
    |> validate_format(:hostname, ~r/^[a-zA-Z0-9-]+$/, message: "must be A-Za-z0-9 or hyphen")
    |> validate_length(:hostname, max: 253)
    |> validate_required([:hostname, :klipper_config, :public_key])
    |> validate_format(:public_key, ~r/^(?!.*private).*$/, message: "looks like a private key")
    |> validate_change(:public_key, &errors_for/2)
    |> validate_inclusion(:timezone, Tzdata.zone_list(), message: "must be a valid timezone")
  end

  def current_versions_changeset(image, versions) do
    image
    |> Ecto.Changeset.cast(
      %{
        current_versions_updated_at: DateTime.utc_now(:second),
        current_versions: versions
      },
      [:current_versions_updated_at]
    )
    |> Ecto.Changeset.cast_embed(:current_versions)
  end

  def options_for_machine do
    @options_for_machine
  end

  defp errors_for(:public_key, nil), do: []

  defp errors_for(:public_key, key) do
    case :ssh_file.decode(key, :public_key) do
      {:error, type} -> [public_key: {"not a valid key", validation: type}]
      _ -> []
    end
  end

  defimpl Klix.ToNix do
    def to_nix(%Klix.Images.Image{} = image) do
      """
      {
        inputs = {
          nixpkgs.url = "github:NixOS/nixpkgs/e6cb50b7edb109d393856d19b797ba6b6e71a4fc";
          klipperConfig = #{image.klipper_config |> Klix.ToNix.to_nix() |> Klix.indent(from: 1) |> Klix.indent(from: 1)};
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
            packages.aarch64-linux.image = self.nixosConfigurations.default.config.system.build.sdImage;
            nixosConfigurations.default = klix.lib.nixosSystem {
              modules = [
                (
                  { pkgs, ... }:
                  {
                    environment.systemPackages = [
                      (pkgs.writeShellApplication {
                        name = "klix-update";
                        runtimeInputs = [
                          klix.packages.aarch64-linux.url
                        ];
                        text = ''
                          dir="$(mktemp)"
                          (
                            cd "$dir"
                            curl "$(klix-url #{image.uri_id} config.tar.gz#default)" | tar -x
                            nixos-rebuild switch --flake .
                            nix eval .#versions | curl --request PUT --json @- "$(klix-url #{image.uri_id} versions)"
                          )
                          rm -rf "$dir"
                        '';
                      })
                    ];
                    imports = klix.lib.machineImports.#{machine_import(image)};
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
                )
              ];
            };
            versions = klix.versions;
          };
      }
      """
    end

    defp machine_import(%Klix.Images.Image{machine: machine}) do
      machine
      |> to_string()
      |> String.replace("_", "-")
    end
  end

  defmodule Query do
    alias Klix.Images.Image

    import Ecto.Query

    def base do
      from(Image, as: :images)
      |> where([images: i], is_nil(i.deleted_at))
      |> order_by([images: i], desc: i.id)
    end

    def for_scope(query \\ base(), scope) do
      where(query, [images: i], i.user_id == ^scope.user.id)
    end
  end
end
