defmodule KlixWeb.MachineAuth do
  import Plug.Conn

  alias Klix.Accounts.Scope
  alias Klix.Encryption
  alias Klix.Images
  alias Klix.Images.Image

  @utc_offset 0
  @tolerance_mins 5

  def fetch_current_scope_for_machine(
        %{
          params: %{
            "uuid" => uuid,
            "datetime" => datetime,
            "sshsig" => b64_ssh_sig
          }
        } = conn,
        _opts
      ) do
    now = DateTime.utc_now()

    with {:ok, parsed_datetime, @utc_offset} <- DateTime.from_iso8601(datetime),
         diff when diff < @tolerance_mins <-
           DateTime.diff(now, parsed_datetime, :minute) |> abs(),
         {:ok, armoured_signature} <- Base.decode64(b64_ssh_sig),
         signature <- Encryption.SSHSig.parse(armoured_signature),
         %Image{} = image <- Images.find(uuid),
         true <- image.host_public_key in [nil, signature.public_key],
         true <- Encryption.verify(signature, message: [uuid, datetime]),
         {:ok, _image} <- Images.set_host_public_key(image, signature.public_key) do
      assign(conn, :current_scope, Scope.for_image(image))
    else
      _ ->
        assign(conn, :current_scope, Scope.for_user(nil))
    end
  end
end
