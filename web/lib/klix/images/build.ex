defmodule Klix.Images.Build do
  use Ecto.Schema

  import Ecto.Changeset

  schema "builds" do
    field :flake_nix, :string
    field :flake_lock, :string
    field :output_path, :string
    field :completed_at, :utc_datetime
    field :error, :string

    belongs_to :image, Klix.Images.Image

    timestamps(type: :utc_datetime)
  end

  def success_changeset(build) do
    change(build, completed_at: DateTime.utc_now(:second))
  end

  def failure_changeset(build, error) do
    build
    |> success_changeset()
    |> change(error: error)
  end

  defmodule Query do
    import Ecto.Query

    alias Klix.Images.Build

    def base do
      from(Build, as: :builds)
    end

    def for_scope(query \\ base(), scope) do
      image = from i in Klix.Images.Image, where: i.user_id == ^scope.user.id
      join(query, :inner, [builds: b], i in ^image, on: i.id == b.image_id)
    end

    def next(query \\ base()) do
      query
      |> where([builds: b], is_nil(b.output_path))
      |> order_by([builds: b], asc: b.inserted_at, asc: b.id)
      |> limit(1)
      |> preload([:image])
    end
  end
end
