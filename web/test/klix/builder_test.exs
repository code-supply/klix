defmodule Klix.BuilderTest do
  use Klix.DataCase, async: true

  @moduletag :tmp_dir

  describe "when an incomplete build is found" do
    setup do
      {:ok, image} = Klix.Factory.params(:image) |> Klix.Images.create()
      %{image: image}
    end

    test "emits an event", ctx do
      %{ref: ref} = start_builder(ctx)
      expected_id = ctx.image.id
      [%{id: expected_build_id}] = ctx.image.builds

      assert_receive {[:builder, :build_setup_complete], ^ref, _empty_measurements,
                      %{image_id: ^expected_id, build_id: ^expected_build_id}}
    end

    test "writes the image's flake", ctx do
      %{ref: ref} = start_builder(ctx)

      assert_receive {[:builder, :build_setup_complete], ^ref, _measurements, _meta}

      assert ctx.tmp_dir |> Path.join("flake.nix") |> File.read() ==
               {:ok, Klix.Images.to_flake(ctx.image)}
    end

    test "runs the build", ctx do
      %{ref: ref, builder: builder} = start_builder(ctx)

      assert_receive {[:builder, :build_setup_complete], ^ref, _measurements, _meta}

      send(builder, :run)

      assert_receive {[:builder, :build_started], ^ref, %{port: port}, _meta}

      assert Port.info(port)

      send(builder, {port, {:exit_status, 0}})

      assert_receive {[:builder, :build_completed], ^ref, %{}, _meta}
    end

    test "emits log messages as telemetry", ctx do
      %{ref: ref, builder: builder} = start_builder(ctx)
      send(builder, :run)
      assert_receive {[:builder, :build_log], ^ref, %{content: content}, _meta}
      # output of 'yes'
      assert content =~ "y\ny\ny\n"
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
      [:builder, :build_completed],
      [:builder, :build_log],
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
        build_dir: tmp_dir, cmd: "yes"
      })

    assert_receive {[:builder, :idle], ^ref, _empty_measurements, _meta}
    Ecto.Adapters.SQL.Sandbox.allow(Klix.Repo, self(), builder)
    send(builder, :set_up)
    %{ref: ref, builder: builder}
  end
end
