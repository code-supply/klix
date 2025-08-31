defmodule Klix.BuilderTest do
  use Klix.DataCase, async: true

  # avoid nix/git issues by creating tmp_dir in /tmp
  @moduletag tmp_dir:
               __DIR__
               |> Path.split()
               |> Enum.map(fn _ -> ".." end)
               |> Path.join()
               |> Path.join("tmp")
               |> Path.join("klix-builder-test")

  setup ctx, do: File.mkdir_p!(ctx.tmp_dir)

  describe "when an incomplete build is found" do
    test "emits an event", ctx do
      {:ok, %{id: id}} = Klix.Factory.params(:image) |> Klix.Images.create()

      %{ref: ref} = start_builder(ctx)

      assert_receive {[:builder, :build_setup_complete], ^ref, %{image_id: ^id}, _meta}
    end

    test "creates a directory with the image's flake", ctx do
      {:ok, image} = Klix.Factory.params(:image) |> Klix.Images.create()

      %{ref: ref} = start_builder(ctx)

      assert_receive {[:builder, :build_setup_complete], ^ref, _measurements, _meta}

      assert ctx.tmp_dir |> Path.join("flake.nix") |> File.read() ==
               {:ok, Klix.Images.to_flake(image)}
    end

    test "runs nix build", ctx do
      {:ok, _image} = Klix.Factory.params(:image) |> Klix.Images.create()

      %{ref: ref, builder: builder} = start_builder(ctx)

      assert_receive {[:builder, :build_setup_complete], ^ref, _measurements, _meta}

      send(builder, :run)

      assert_receive {[:builder, :build_started], ^ref, %{port: port}, _meta}

      assert Port.info(port)
    end
  end

  describe "when there's nothing to do" do
    test "emits an event", ctx do
      %{ref: ref} = start_builder(ctx)
      assert_receive {[:builder, :no_builds], ^ref, _empty_measurements, _meta}
    end
  end

  defp subscribe do
    :telemetry_test.attach_event_handlers(self(), [
      [:builder, :build_setup_complete],
      [:builder, :build_started],
      [:builder, :idle],
      [:builder, :no_builds]
    ])
  end

  defp start_builder(%{tmp_dir: tmp_dir}) do
    ref = subscribe()

    builder =
      start_link_supervised!({
        Klix.Builder,
        build_dir: tmp_dir
      })

    assert_receive {[:builder, :idle], ^ref, _empty_measurements, _meta}
    Ecto.Adapters.SQL.Sandbox.allow(Klix.Repo, self(), builder)
    send(builder, :set_up)
    %{ref: ref, builder: builder}
  end
end
