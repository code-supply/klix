defmodule Klix.BuilderTest do
  use Klix.DataCase, async: true

  @moduletag :tmp_dir

  describe "when an incomplete build is found" do
    setup do
      {:ok, image} = Klix.Factory.params(:image) |> Klix.Images.create()
      %{image: image}
    end

    test "emits an event after setup message is sent", ctx do
      %{ref: ref, builder: builder} = start_builder(ctx)
      expected_id = ctx.image.id
      [%{id: expected_build_id}] = ctx.image.builds

      assert_receive {[:builder, :setup_complete], ^ref, _empty_measurements,
                      %{image_id: ^expected_id, build_id: ^expected_build_id, pid: ^builder}}
    end

    test "deletes existing data in the build dir", ctx do
      flake_nix = Path.join(ctx.tmp_dir, "flake.nix")
      flake_lock = Path.join(ctx.tmp_dir, "flake.lock")
      File.write!(flake_nix, "hi there")
      File.touch!(flake_lock)

      %{ref: ref} = start_builder(ctx)

      assert_receive {[:builder, :setup_complete], ^ref, _empty_measurements, _metadata}

      assert File.read!(flake_nix) != "hi there"
      refute File.exists?(flake_lock)
    end

    test "writes the image's flake", ctx do
      %{ref: ref, builder: builder} = start_builder(ctx)

      assert_receive {[:builder, :setup_complete], ^ref, _measurements, %{pid: ^builder}}

      assert ctx.tmp_dir |> Path.join("flake.nix") |> File.read() ==
               {:ok, Klix.Images.to_flake(ctx.image)}
    end

    test "runs the build and stores completion time", ctx do
      %{builds: [build]} = ctx.image
      build_id = build.id

      %{ref: ref, builder: builder} = start_builder(ctx)

      assert_receive {[:builder, :setup_complete], ^ref, _measurements, %{pid: ^builder}}

      send(builder, :run)

      assert_receive {[:builder, :build_started], ^ref, _empty_measurements,
                      %{port: port, pid: ^builder}}

      assert Port.info(port)

      Klix.Images.subscribe(ctx.image.id)
      send(builder, {port, {:exit_status, 0}})
      assert_receive build_ready: %Klix.Images.Build{id: ^build_id}

      assert_receive {[:builder, :run_complete], ^ref, %{}, %{pid: ^builder}}

      assert DateTime.compare(Klix.Repo.reload!(build).completed_at, DateTime.utc_now()) in [
               :lt,
               :eq
             ]
    end

    test "stores the flake.nix and flake.lock files when they're both ready", ctx do
      nix_message =
        "warning: creating lock file \"/tmp/klix-build/flake.lock\": \n• Added input 'klipperConfig'"

      %{ref: ref, builder: builder} = start_builder(ctx)
      send(builder, :run)

      assert_receive {[:builder, :build_started], ^ref, _empty_measurements,
                      %{port: port, pid: ^builder}}

      ctx.tmp_dir
      |> Path.join("flake.nix")
      |> File.write!("flake.nix file content")

      ctx.tmp_dir
      |> Path.join("flake.lock")
      |> File.write!("flake.lock file content")

      send(builder, {port, {:data, nix_message}})
      assert_receive {[:builder, :build_log], ^ref, _measurements, %{pid: ^builder}}

      %{builds: [build]} = ctx.image

      build = Klix.Repo.reload!(build)

      assert build.flake_nix == "flake.nix file content"
      assert build.flake_lock == "flake.lock file content"
    end

    test "stores the output path when available", ctx do
      nix_message =
        "[{\"drvPath\":\"/nix/store/j2hvqq83fhr8p6jpwkbhsjidh6dvcm1j-nixos-image-sd-card-25.11.20250831.e6cb50b-aarch64-linux.img.zst.drv\",\"outputs\":{\"out\":\"/nix/store/6rwl2k7a7ad0prmjsacz2d3lw9s3z0dh-nixos-image-sd-card-25.11.20250831.e6cb50b-aarch64-linux.img.zst\"}}]\n"

      %{ref: ref, builder: builder} = start_builder(ctx)
      send(builder, :run)

      assert_receive {[:builder, :build_started], ^ref, _empty_measurements,
                      %{port: port, pid: ^builder}}

      send(builder, {port, {:data, nix_message}})
      assert_receive {[:builder, :build_log], ^ref, _measurements, %{pid: ^builder}}

      %{builds: [build]} = ctx.image

      build = Klix.Repo.reload!(build)

      assert build.output_path ==
               "/nix/store/6rwl2k7a7ad0prmjsacz2d3lw9s3z0dh-nixos-image-sd-card-25.11.20250831.e6cb50b-aarch64-linux.img.zst"
    end

    test "emits log messages as telemetry", ctx do
      %{ref: ref, builder: builder} = start_builder(ctx)
      send(builder, :run)
      assert_receive {[:builder, :build_log], ^ref, %{content: content}, %{pid: ^builder}}
      # output of 'yes'
      assert content =~ "@nix {}\n"
    end
  end

  describe "when there's nothing to do" do
    test "emits an event", ctx do
      %{ref: ref, builder: builder} = start_builder(ctx)
      assert_receive {[:builder, :nothing_to_do], ^ref, _empty_measurements, %{pid: ^builder}}
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
        build_dir: tmp_dir, cmd: "yes @nix {}"
      })

    assert_receive {[:builder, :idle], ^ref, _empty_measurements, %{pid: ^builder}}
    Ecto.Adapters.SQL.Sandbox.allow(Klix.Repo, self(), builder)
    send(builder, :set_up)
    %{ref: ref, builder: builder}
  end
end
