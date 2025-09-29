defmodule Klix.Encryption do
  def verify(opts) do
    import Klix.Encryption.SSHSig

    armoured_public_key = Keyword.fetch!(opts, :public_key)
    armoured_signature = Keyword.fetch!(opts, :signature)
    raw_message = Keyword.fetch!(opts, :message)
    ssh_sig = parse(armoured_signature)
    reserved = ""
    hash = :crypto.hash(:sha512, raw_message)
    ["ssh-ed25519", b64_public_key, _comment] = String.split(armoured_public_key, " ")
    public_key = b64_public_key |> Base.decode64!() |> raw(length: 32)

    message =
      <<
        magic_preamble()::binary,
        string("file")::binary,
        string(reserved)::binary,
        string(ssh_sig.hash_algorithm)::binary,
        string(hash)::binary
      >>

    :crypto.verify(
      :eddsa,
      :none,
      message,
      ssh_sig.signature,
      [public_key, :ed25519]
    )
  end

  @aad "donttamper"
  @bytes 32

  def generate_key, do: :crypto.strong_rand_bytes(@bytes)

  def encrypt(text, key) do
    initialisation_vector = :crypto.strong_rand_bytes(@bytes)

    {ciphertext, ciphertag} =
      :crypto.crypto_one_time_aead(
        :aes_256_gcm,
        key,
        initialisation_vector,
        text,
        @aad,
        true
      )

    Base.encode64(initialisation_vector <> ciphertag <> ciphertext)
  end

  def decrypt(encrypted, key) do
    <<initialisation_vector::binary-@bytes, ciphertag::binary-16, ciphertext::binary>> =
      Base.decode64!(encrypted)

    :crypto.crypto_one_time_aead(
      :aes_256_gcm,
      key,
      initialisation_vector,
      ciphertext,
      @aad,
      ciphertag,
      false
    )
  end
end
