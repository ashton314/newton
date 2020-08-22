defmodule Newton.QueryParser do
  @moduledoc """
  Parses query strings for searching questions.

  ## Query Syntax

  Search for tags by wrapping them in `[]`. E.g. "foo [hard]" find
  questions matching "foo" with tag "hard".

  Restrict to questions matching a chapter and section with `{}`. E.g.
  "{2}" will restrict search to things in chapter 2, and `{3.7}` will
  only show questions from chapter 3, section 7.

  All other text will be searched through the question text.
  """

  def parse(query) do
    query
    |> tokenize
    |> parse_tokens
    |> Map.update!(:refs, fn refs -> Enum.filter(refs, & &1) end)
    |> Map.update!(:refs, fn refs -> Enum.filter(refs, & &1) end)
    |> Map.update!(:normal, fn norms -> Enum.filter(norms, & &1 != "") end)
    |> Map.update!(:tags, fn tags -> Enum.filter(tags, & &1 != "") end)
  end

  def tokenize(query), do: Regex.split(~r/ /, query)

  def parse_tokens(token_stream, parsed \\ %{tags: [], refs: [], normal: []})

  def parse_tokens([], parsed), do: parsed

  def parse_tokens([tok | rest], parsed) do
    cond do
      Regex.match?(~r/^\[.*\]$/, tok) ->
	parse_tokens(rest, Map.update!(parsed, :tags, &[strip(tok) | &1]))

      Regex.match?(~r/^\{\d+(\.\d+)?\}$/, tok) ->
	parse_tokens(rest, Map.update!(parsed, :refs, &[parse_ref(tok) | &1]))

      true ->
	parse_tokens(rest, Map.update!(parsed, :normal, &[tok | &1]))
    end
  end

  def parse_ref(ref) do
    res =
      Regex.named_captures(~r/\{(?<chapter>[[:digit:]]*)(\.(?<section>[[:digit:]]+))?\}/, ref)

    if res["chapter"] && res["chapter"] != "" do
      if res["section"] && res["section"] != "" do
	{c, _} = Integer.parse(res["chapter"])
	{s, _} = Integer.parse(res["section"])
	%{chapter: c, section: s}
      else
	{c, _} = Integer.parse(res["chapter"])
	%{chapter: c}
      end
    else
      nil
    end
  end

  defp strip(str) do
    String.trim(str, "[")
    |> String.trim("]")
    |> String.trim("{")
    |> String.trim("}")
  end
end
