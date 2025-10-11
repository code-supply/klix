defmodule Klix.BuilderTest do
  use Klix.DataCase, async: true

  alias Klix.Builder

  import Klix.ToNix

  @moduletag :tmp_dir

  @stub_klipper_version "1.2.3"

  setup do: %{
          uploader: fn _source, _destination -> :ok end,
          version_retriever: fn _path ->
            {
              :ok,
              %{
                "cage" => "1.2.3",
                "klipper" => @stub_klipper_version
              }
            }
          end
        }

  describe "when an incomplete build is found" do
    setup do
      scope = user_fixture() |> Scope.for_user()
      {:ok, image} = Images.create(scope, Factory.params(:image))
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
               {:ok, to_nix(ctx.image)}
    end

    test "runs the build, stores versions and uploads to cloud", ctx do
      %{builds: [build]} = ctx.image
      build_id = build.id

      ctx = %{
        ctx
        | uploader: fn from, to ->
            assert String.ends_with?(from, "the-only-file-in-here")
            assert to == "builds/#{build.id}.img.zst"
            :ok
          end
      }

      %{ref: ref, builder: builder} = start_builder(ctx)

      assert_receive {[:builder, :setup_complete], ^ref, _measurements, %{pid: ^builder}}

      send(builder, :run)

      assert_receive {[:builder, :build_started], ^ref, _empty_measurements,
                      %{port: port, pid: ^builder}}

      assert Port.info(port)

      nix_writes_to_disk(builder, port, ctx.tmp_dir)

      Images.subscribe(ctx.image.id)
      send(builder, {port, {:exit_status, 0}})

      assert_receive {[:builder, :versions_stored], ^ref, %{}, %{pid: ^builder}}

      build = Repo.reload!(build)
      assert build.versions.klipper == @stub_klipper_version

      assert_receive {[:builder, :uploading], ^ref, %{}, %{pid: ^builder}}
      assert_receive build_ready: %Images.Build{id: ^build_id}
      assert_receive {[:builder, :run_complete], ^ref, %{}, %{pid: ^builder}}

      build = Repo.reload!(build)

      assert DateTime.compare(build.completed_at, DateTime.utc_now()) in [:lt, :eq]
      assert Images.build_ready?(build)
    end

    test "if cloud upload fails, store error and set as completed", ctx do
      %{builds: [build]} = ctx.image
      build_id = build.id

      ctx = %{ctx | uploader: fn _from, _to -> {:error, "bad stuff"} end}

      %{ref: ref, builder: builder} = start_builder(ctx)

      assert_receive {[:builder, :setup_complete], ^ref, _measurements, %{pid: ^builder}}

      send(builder, :run)

      assert_receive {[:builder, :build_started], ^ref, _empty_measurements,
                      %{port: port, pid: ^builder}}

      assert Port.info(port)

      nix_writes_to_disk(builder, port, ctx.tmp_dir)

      Images.subscribe(ctx.image.id)
      send(builder, {port, {:exit_status, 0}})

      assert_receive {[:builder, :uploading], ^ref, %{}, %{pid: ^builder}}
      assert_receive build_ready: %Images.Build{id: ^build_id}
      assert_receive {[:builder, :run_complete], ^ref, %{}, %{pid: ^builder}}

      build = Repo.reload!(build)

      assert build.error == "bad stuff"

      assert DateTime.compare(build.completed_at, DateTime.utc_now()) in [:lt, :eq]

      assert Images.build_ready?(build)
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

      build = Repo.reload!(build)

      assert build.flake_nix == "flake.nix file content"
      assert build.flake_lock == "flake.lock file content"
    end

    test "stores the file size when available", ctx do
      %{ref: ref, builder: builder} = start_builder(ctx)
      send(builder, :run)

      assert_receive {[:builder, :build_started], ^ref, _empty_measurements,
                      %{port: port, pid: ^builder}}

      nix_writes_to_disk(builder, port, ctx.tmp_dir, "123")
      assert_receive {[:builder, :build_log], ^ref, _measurements, %{pid: ^builder}}

      %{builds: [build]} = ctx.image

      assert Repo.reload!(build).byte_size == byte_size("123")
    end

    test "emits log messages as telemetry", ctx do
      %{ref: ref, builder: builder} = start_builder(ctx)
      send(builder, :run)
      assert_receive {[:builder, :build_log], ^ref, %{content: content}, %{pid: ^builder}}
      # output of 'yes'
      assert content =~ "@nix {}\n"
    end

    test "on failure, emits completion and records failed state",
         %{image: %{builds: [build]}} = ctx do
      %{ref: ref, builder: builder} = start_builder(ctx, "false")
      send(builder, :run)
      assert_receive {[:builder, :run_complete], ^ref, _empty_measurements, %{pid: ^builder}}

      build = Repo.reload!(build)

      assert %DateTime{} = build.completed_at
      assert build.error == "nonzero exit code: 1"
    end
  end

  describe "when there's nothing to do" do
    test "emits an event", ctx do
      %{ref: ref, builder: builder} = start_builder(ctx)
      assert_receive {[:builder, :nothing_to_do], ^ref, _empty_measurements, %{pid: ^builder}}
    end
  end

  defp nix_writes_to_disk(builder, port, dir, contents \\ "123456") do
    nix_message =
      ~s([{"drvPath":"/some/path/foo.drv","outputs":{"out":"#{dir}"}}]\n)

    write_image(dir, contents)
    send(builder, {port, {:data, nix_message}})
  end

  defp subscribe do
    :telemetry_test.attach_event_handlers(self(), Builder.telemetry_events())
  end

  defp start_builder(
         %{tmp_dir: tmp_dir, uploader: uploader, version_retriever: version_retriever},
         cmd \\ "yes @nix {}"
       ) do
    ref = subscribe()

    builder =
      start_link_supervised!({
        Builder,
        build_dir: tmp_dir, cmd: cmd, uploader: uploader, version_retriever: version_retriever
      })

    assert_receive {[:builder, :idle], ^ref, _empty_measurements, %{pid: ^builder}}
    Ecto.Adapters.SQL.Sandbox.allow(Repo, self(), builder)
    send(builder, :set_up)
    %{ref: ref, builder: builder}
  end
end
