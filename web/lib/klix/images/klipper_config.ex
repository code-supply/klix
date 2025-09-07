defmodule Klix.Images.KlipperConfig do
  use Ecto.Schema

  @types [github: "GitHub", gitlab: "GitLab"]

  def type_options, do: for({k, v} <- @types, do: {v, k})

  embedded_schema do
    field :type, Ecto.Enum, values: Keyword.keys(@types)
    field :owner, :string
    field :repo, :string
  end

  def changeset(config, params) do
    import Ecto.Changeset

    config
    |> cast(params, [:type, :owner, :repo])
    |> validate_required([:type, :owner, :repo])
  end

  defimpl Klix.ToNix do
    def to_nix(config) do
      """
      {
        type = "github";
        owner = "#{config.owner}";
        repo = "#{config.repo}";
      }\
      """
    end
  end
end
