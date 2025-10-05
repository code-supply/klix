defmodule Klix.TestSupport.Image do
  def write_image(dir, contents) do
    top_dir = Path.join(dir, "some-dir")
    sd_image_dir = Path.join(top_dir, "sd-image")
    File.mkdir_p!(sd_image_dir)
    image_path = Path.join(sd_image_dir, "the-only-file-in-here")
    File.write!(image_path, contents)
    top_dir
  end
end
