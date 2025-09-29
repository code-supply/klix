defmodule Klix.Encryption.SSHSig do
  @header "-----BEGIN SSH SIGNATURE-----"
  @footer "-----END SSH SIGNATURE-----"
  @magic_preamble "SSHSIG"

  defstruct [:hash_algorithm, :namespace, :public_key, :signature, :version]

  def magic_preamble, do: @magic_preamble

  def string(s) do
    s = to_string(s)
    <<byte_size(s)::32, s::binary>>
  end

  def parse(armoured) do
    armoured
    |> String.replace([@header, @footer], "")
    |> String.replace(~r/\s/, "")
    |> Base.decode64!()
    |> parse_bytes()
  end

  def raw(<<11::32, "ssh-ed25519", length::32, raw::binary>>, length: length), do: raw

  defp parse_bytes(
         <<@magic_preamble, version::32, public_key_size::32,
           public_key::binary-size(public_key_size), namespace_size::32,
           namespace::binary-size(namespace_size), reserved_size::32,
           _reserved::binary-size(reserved_size), hash_algorithm_size::32,
           hash_algorithm::binary-size(hash_algorithm_size), signature_size::32,
           signature::binary-size(signature_size)>>
       ) do
    %__MODULE__{
      hash_algorithm: String.to_existing_atom(hash_algorithm),
      namespace: namespace,
      public_key: raw(public_key, length: 32),
      signature: raw(signature, length: 64),
      version: version
    }
  end
end
