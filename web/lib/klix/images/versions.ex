defmodule Klix.Images.Versions do
  use Ecto.Schema

  @permitted_attrs [
    :cage,
    :fluidd,
    :kamp,
    :klipper,
    :klipperscreen,
    :linux,
    :klix,
    :moonraker,
    :nginx,
    :"nixos-raspberrypi",
    :nixpkgs,
    :plymouth,
    :shaketune,
    :wayland,
    :z_calibration
  ]

  def permitted_attrs, do: @permitted_attrs

  embedded_schema do
    field :cage
    field :fluidd
    field :kamp
    field :klipper
    field :klipperscreen
    field :linux
    field :klix
    field :moonraker
    field :nginx
    field :"nixos-raspberrypi"
    field :nixpkgs
    field :plymouth
    field :shaketune
    field :wayland
    field :z_calibration
  end

  def changeset(version, params) do
    Ecto.Changeset.cast(version, params, @permitted_attrs)
  end
end
