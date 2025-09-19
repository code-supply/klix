defmodule Klix.Images.Image do
  use Ecto.Schema

  schema "images" do
    field :hostname, :string
    field :timezone, :string, default: "Europe/London"
    field :klipperscreen_enabled, :boolean, default: true
    field :plugin_kamp_enabled, :boolean, default: true
    field :plugin_shaketune_enabled, :boolean, default: true
    field :plugin_z_calibration_enabled, :boolean, default: true
    field :public_key, :string

    belongs_to :user, Klix.Accounts.User
    has_many :builds, Klix.Images.Build
    embeds_one :klipper_config, Klix.Images.KlipperConfig

    timestamps(type: :utc_datetime)
  end

  def changeset(image, params) do
    import Ecto.Changeset

    image
    |> cast(params, [
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
    |> validate_change(:public_key, &errors_for/2)
    |> validate_inclusion(:timezone, Tzdata.zone_list(), message: "must be a valid timezone")
  end

  defp errors_for(:public_key, nil), do: []

  defp errors_for(:public_key, key) do
    case :ssh_file.decode(key, :public_key) do
      {:error, type} -> [public_key: {"not a valid key", validation: type}]
      _ -> []
    end
  end

  defmodule Query do
    alias Klix.Images.Image

    import Ecto.Query

    def base do
      from(Image, as: :images)
      |> order_by([images: i], desc: i.id)
    end

    def for_scope(query \\ base(), scope) do
      where(query, [images: i], i.user_id == ^scope.user.id)
    end
  end
end
