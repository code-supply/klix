defmodule Klix.S3UploadTest do
  use Klix.DataCase, async: true

  @tag :tmp_dir
  test "can send a build's output successfully", %{tmp_dir: dir} do
    write_image(dir, "hi there")
    assert :ok = Images.s3_uploader(%Images.Build{id: 123, output_path: "#{dir}/some-dir"})
  end

  test "it's an error when build dir has gone" do
    assert {:error, :sd_dir_not_found} =
             Images.s3_uploader(%Images.Build{id: 123, output_path: "/tmp/nonexistent/place"})
  end
end
