defmodule Klix.Encryption do
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
