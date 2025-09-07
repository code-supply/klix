defmodule Klix.Factory do
  def params(kind, attributes \\ [])

  def params(:image, attributes) do
    [{_name, first_type} | _rest] = Ecto.Enum.mappings(Klix.Images.KlipperConfig, :type)

    [
      hostname: "some-printer",
      klipper_config: [
        type: first_type,
        owner: "code-supply",
        repo: "my-config"
      ],
      timezone: "Europe/Madrid",
      public_key:
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINxmQDDdlqsMmQ69TsBWxqFOPfyipAX0h+4GGELsGRup nobody@ever"
    ]
    |> Keyword.merge(attributes)
    |> Enum.into(%{})
  end

  def params(:build, attributes) do
    []
    |> Keyword.merge(attributes)
    |> Enum.into(%{})
  end
end
