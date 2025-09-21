defmodule Klix.EncryptionTest do
  use ExUnit.Case, async: true

  test "can encrypt and decrypt" do
    key = Klix.Encryption.generate_key()

    encrypted = Klix.Encryption.encrypt("hello there", key)

    refute encrypted =~ "hello there"
    assert Klix.Encryption.decrypt(encrypted, key) == "hello there"
  end
end
