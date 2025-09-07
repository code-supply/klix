defmodule Klix do
  @moduledoc """
  Klix keeps the contexts that define your domain
  and business logic.

  Contexts are also responsible for managing your data, regardless
  if it comes from the database, an external API or others.
  """

  defprotocol ToNix do
    def to_nix(term)
  end

  @spec indent(String.t() | nil) :: String.t()
  def indent(nil) do
    ""
  end

  def indent(str) do
    ("  " <> str)
    |> String.replace(~r/\n(.+)/, "\n  \\1")
    |> String.replace(~r/^ +$/, "")
  end

  def indent(str, from: start_line) do
    lines = String.split(str, "\n")
    not_indented = Enum.take(lines, start_line)
    indented = Enum.drop(lines, start_line)

    not_indented_result = not_indented |> Enum.join("\n")
    indent_result = indented |> Enum.map_join("\n", &indent/1)

    [not_indented_result, indent_result] |> Enum.join("\n")
  end
end
