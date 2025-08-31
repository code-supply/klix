defmodule Klix.BuilderTest do
  use Klix.DataCase, async: true

  @moduletag :tmp_dir

  describe "when an incomplete build is found" do
    test "emits an event", ctx do
      {:ok, %{id: id}} = Klix.Factory.params(:image) |> Klix.Images.create()

      ref = start_builder(ctx)

      assert_receive {[:builder, :build_setup_complete], ^ref, %{image_id: ^id}, _meta}
    end

    test "creates a directory with the image's flake", ctx do
      {:ok, %{id: id} = image} = Klix.Factory.params(:image) |> Klix.Images.create()

      ref = start_builder(ctx)

      assert_receive {[:builder, :build_setup_complete], ^ref, %{image_id: ^id}, _meta}

      assert ctx.tmp_dir |> Path.join("flake.nix") |> File.read() ==
               {:ok, Klix.Images.to_flake(image)}
    end
  end

  describe "when there's nothing to do" do
    test "emits an event", ctx do
      ref = start_builder(ctx)
      assert_receive {[:builder, :no_builds], ^ref, _empty_measurements, _meta}
    end
  end

  defp subscribe do
    :telemetry_test.attach_event_handlers(self(), [
      [:builder, :build_setup_complete],
      [:builder, :idle],
      [:builder, :no_builds]
    ])
  end

  defp start_builder(%{tmp_dir: tmp_dir}) do
    ref = subscribe()

    builder =
      start_link_supervised!({
        Klix.Builder,
        scheduler: self(), build_dir: tmp_dir
      })

    assert_receive {[:builder, :idle], ^ref, _empty_measurements, _meta}
    Ecto.Adapters.SQL.Sandbox.allow(Klix.Repo, self(), builder)
    send(builder, :run)
    ref
  end
end
