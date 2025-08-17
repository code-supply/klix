defmodule Klix.Hostname do
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
