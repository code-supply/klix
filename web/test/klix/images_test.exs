defmodule Klix.ImagesTest do
  use Klix.DataCase, async: true
  use ExUnitProperties

  defmodule Hostname do
    import StreamData

    @valid_first_chars [?a..?z, ?A..?Z, ?0..?9]
    @valid_subsequent_chars [?- | @valid_first_chars]

    def generator do
      bind(first_char(), fn first ->
        bind(subsequent_chars(max_length: 252), fn rest ->
          constant("#{first}#{rest}")
        end)
      end)
    end

    defp first_char do
      @valid_first_chars
      |> string(length: 1)
    end

    defp subsequent_chars(opts) do
      @valid_subsequent_chars
      |> string(opts)
      |> filter(&(!String.ends_with?(&1, "-")))
    end
  end

  describe "hostname" do
    property "valid when string of a-zA-Z 0-9 or hyphen" do
      check all hostname <- Hostname.generator() do
        assert {:ok, _} = Klix.Images.create(%{"hostname" => hostname})
      end
    end

    property "invalid if longer than 253 characters" do
      check all hostname <- string(:ascii, min_length: 254) do
        {:error, changeset} = Klix.Images.create(%{"hostname" => hostname})

        assert changeset.errors[:hostname] ==
                 {"should be at most %{count} character(s)",
                  [{:count, 253}, {:validation, :length}, {:kind, :max}, {:type, :string}]}
      end
    end

    test "hostname may not start or end with a hyphen" do
      {:error, starts_with_hyphen} = Klix.Images.create(%{"hostname" => "-foo"})
      {:error, ends_with_hyphen} = Klix.Images.create(%{"hostname" => "foo-"})

      assert starts_with_hyphen.errors[:hostname] ==
               {"must not start with a hyphen", validation: :format}

      assert ends_with_hyphen.errors[:hostname] ==
               {"must not end with a hyphen", validation: :format}
    end
  end
end
