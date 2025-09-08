defmodule Klix.Images.KlipperConfig do
  use Ecto.Schema

  @types [github: "GitHub", gitlab: "GitLab"]

  def type_options, do: for({k, v} <- @types, do: {v, k})

  embedded_schema do
    field :type, Ecto.Enum, values: Keyword.keys(@types)
    field :owner, :string
    field :repo, :string
    field :path, :string
  end

  def changeset(config, params) do
    import Ecto.Changeset

    config
    |> cast(params, [:type, :owner, :path, :repo])
    |> validate_required([:type, :owner, :repo])
  end

  defimpl Klix.ToNix do
    def to_nix(config) do
      """
      {
        type = "github";
        owner = "#{config.owner}";
        repo = "#{config.repo}";
        flake = false;
      }\
      """
    end
  end
end
