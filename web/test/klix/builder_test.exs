defmodule Klix.BuilderTest do
  use Klix.DataCase, async: true

  @moduletag :tmp_dir

  describe "when an incomplete build is found" do
    setup do
      {:ok, image} = Klix.Factory.params(:image) |> Klix.Images.create()
      %{image: image}
    end

    test "emits an event", ctx do
      %{ref: ref, builder: builder} = start_builder(ctx)
      expected_id = ctx.image.id
      [%{id: expected_build_id}] = ctx.image.builds

      assert_receive {[:builder, :build_setup_complete], ^ref, _empty_measurements,
                      %{image_id: ^expected_id, build_id: ^expected_build_id, pid: ^builder}}
    end

    test "writes the image's flake", ctx do
      %{ref: ref, builder: builder} = start_builder(ctx)

      assert_receive {[:builder, :build_setup_complete], ^ref, _measurements, %{pid: ^builder}}

      assert ctx.tmp_dir |> Path.join("flake.nix") |> File.read() ==
               {:ok, Klix.Images.to_flake(ctx.image)}
    end

    test "runs the build", ctx do
      %{ref: ref, builder: builder} = start_builder(ctx)

      assert_receive {[:builder, :build_setup_complete], ^ref, _measurements, %{pid: ^builder}}

      send(builder, :run)

      assert_receive {[:builder, :build_started], ^ref, _empty_measurements,
                      %{port: port, pid: ^builder}}

      assert Port.info(port)

      send(builder, {port, {:exit_status, 0}})

      assert_receive {[:builder, :build_completed], ^ref, %{}, %{pid: ^builder}}
    end

    test "emits log messages as telemetry", ctx do
      %{ref: ref, builder: builder} = start_builder(ctx)
      send(builder, :run)
      assert_receive {[:builder, :build_log], ^ref, %{content: content}, %{pid: ^builder}}
      # output of 'yes'
      assert content =~ "y\ny\ny\n"
    end
  end

  describe "when there's nothing to do" do
    test "emits an event", ctx do
      %{ref: ref, builder: builder} = start_builder(ctx)
      assert_receive {[:builder, :no_builds], ^ref, _empty_measurements, %{pid: ^builder}}
    end
  end

  defp subscribe do
    :telemetry_test.attach_event_handlers(self(), Klix.Builder.telemetry_events())
  end

  defp start_builder(%{tmp_dir: tmp_dir}) do
    ref = subscribe()

    builder =
      start_link_supervised!({
        Klix.Builder,
        build_dir: tmp_dir, cmd: "yes"
      })

    assert_receive {[:builder, :idle], ^ref, _empty_measurements, %{pid: ^builder}}
    Ecto.Adapters.SQL.Sandbox.allow(Klix.Repo, self(), builder)
    send(builder, :set_up)
    %{ref: ref, builder: builder}
  end
end
