defmodule Klix.SnapshotterTest do
  use Klix.DataCase, async: true

  @tag :tmp_dir
  test "returns a Snapshot and tarball given a flake.nix", %{tmp_dir: dir} do
    flake_nix = """
    {
      inputs = {
        foo.url = "#{dir}";
        foo.flake = false;
      };

      outputs = { foo }: {};
    }
    """

    {:ok, snapshot, tarball} = Klix.Snapshotter.snapshot(flake_nix)

    test_path = "#{dir}/test.tar.gz"
    File.write!(test_path, tarball)
    assert {:ok, [~c"flake.nix", ~c"flake.lock"]} = :erl_tar.table(test_path, [:compressed])

    assert snapshot.flake_lock =~ """
           {
             "nodes": {
               "foo": {
                 "flake": false,
                 "locked": {
                   "lastModified":\
           """

    assert snapshot.flake_nix == flake_nix
  end

  test "returns error if lock can't be created" do
    flake_nix = """
    {
      inputs = {
        foo.url = "/doesnotexist";
        foo.flake = false;
      };

      outputs = { foo }: {};
    }
    """

    assert {:error, :error_updating_lock_file, {_output, 1}} =
             Klix.Snapshotter.snapshot(flake_nix)
  end
end
