defmodule Klix.Images.Build do
  use Ecto.Schema

  import Ecto.Changeset

  schema "builds" do
    field :flake_nix, :string
    field :flake_lock, :string
    field :completed_at, :utc_datetime
    field :error, :string
    field :byte_size, :integer
    field :duration, :string, virtual: true

    embeds_one :versions, Klix.Images.Versions
    belongs_to :image, Klix.Images.Image, where: [deleted_at: nil]

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

    alias Klix.Images
    alias Klix.Images.Build

    def base do
      from(Build, as: :builds)
    end

    def for_scope(query \\ base(), scope) do
      images = Images.Image.Query.for_scope(scope)
      join(query, :inner, [builds: b], i in subquery(images), on: i.id == b.image_id)
    end

    def next(query \\ base()) do
      query
      |> where([builds: b], is_nil(b.completed_at))
      |> order_by([builds: b], asc: b.inserted_at, asc: b.id)
      |> limit(1)
      |> preload([:image])
    end
  end
end
