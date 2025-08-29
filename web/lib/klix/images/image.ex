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

    timestamps()
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
    |> validate_format(:hostname, ~r/^[^-].*$/, message: "must not start with a hyphen")
    |> validate_format(:hostname, ~r/^.*[^-]$/, message: "must not end with a hyphen")
    |> validate_length(:hostname, max: 253)
    |> validate_required([:hostname, :public_key])
  end
end
