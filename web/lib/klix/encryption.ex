defmodule Klix.Encryption do
  def verify(ssh_sig, opts) do
    import Klix.Encryption.SSHSig

    public_key = ssh_sig.public_key
    raw_message = Keyword.fetch!(opts, :message)
    reserved = ""
    hash = :crypto.hash(:sha512, raw_message)

    body =
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
      body,
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
