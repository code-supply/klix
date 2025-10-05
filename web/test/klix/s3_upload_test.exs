defmodule Klix.S3UploadTest do
  use Klix.DataCase, async: true

  @tag :tmp_dir
  test "can send a source file to a destination", %{tmp_dir: dir} do
    File.write!("#{dir}/foo", "hi there")
    assert :ok = Images.s3_uploader("#{dir}/foo", "justatest")
  end

  test "it's an error when source has gone" do
    assert {:error, :source_not_present} =
             Images.s3_uploader("/tmp/not/here", "justatest")
  end
end
