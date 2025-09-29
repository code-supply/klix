defmodule Klix.EncryptionTest do
  use ExUnit.Case, async: true

  alias Klix.Encryption.SSHSig

  test "can encrypt and decrypt" do
    key = Klix.Encryption.generate_key()

    encrypted = Klix.Encryption.encrypt("hello there", key)

    refute encrypted =~ "hello there"
    assert Klix.Encryption.decrypt(encrypted, key) == "hello there"
  end

  test "can parse a signature" do
    signature =
      """
      -----BEGIN SSH SIGNATURE-----
      U1NIU0lHAAAAAQAAADMAAAALc3NoLWVkMjU1MTkAAAAgL+vmaJZuSkJ7sufxvNaaQl93DN
      4UuRatoesv10s6WhcAAAAEZmlsZQAAAAAAAAAGc2hhNTEyAAAAUwAAAAtzc2gtZWQyNTUx
      OQAAAEBplC7sRH5WGk5BpPmVT5xcl7uSG9J9aNhw3uvumwM9Ns4xRLMf6a4TPdWVh9M2rL
      0wqz3bFxD53xaUoBotPRQE
      -----END SSH SIGNATURE-----
      """

    assert %SSHSig{
             hash_algorithm: :sha512,
             namespace: "file",
             public_key: _public_key,
             signature: _signature,
             version: 1
           } = SSHSig.parse(signature)
  end

  test "can verify a message signed by an ed25519 host key" do
    message = "sign this"

    armored_public_key =
      """
      ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIC/r5miWbkpCe7Ln8bzWmkJfdwzeFLkWraHrL9dLOloX andrew@p14s\
      """

    signature =
      """
      -----BEGIN SSH SIGNATURE-----
      U1NIU0lHAAAAAQAAADMAAAALc3NoLWVkMjU1MTkAAAAgL+vmaJZuSkJ7sufxvNaaQl93DN
      4UuRatoesv10s6WhcAAAAEZmlsZQAAAAAAAAAGc2hhNTEyAAAAUwAAAAtzc2gtZWQyNTUx
      OQAAAECAJmYTbHx/G+97Koi/6gH4SQJBlw/n617yzXg/ERJZdKrTq+9xzGSXkTe8sEcACw
      PUc35FCcSPpTrKkslkD6EF
      -----END SSH SIGNATURE-----
      """

    assert Klix.Encryption.verify(
             public_key: armored_public_key,
             message: message,
             signature: signature
           )
  end
end
