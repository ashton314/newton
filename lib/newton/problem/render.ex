defmodule Newton.Problem.Render do
  require EEx
  require Logger

  alias Newton.Problem.Question

  EEx.function_from_file(
    :defp,
    :layout_question_preview,
    "lib/newton/problem/templates/question_preview.latex.eex",
    [:contents]
  )

  def render_image_preview(%Question{id: q_id} = question, callback) do
    layout_question_preview(question.text)
    |> LatexRenderer.image_string_async(callback, dir: q_id)
  end

  @doc """
  Temporary question preview
  """
  def render_question_preview(%Question{} = question, callback) do
    layout_question_preview(question.text)
    |> LatexRenderer.format_string_async(callback)
  end

  @doc """
  Escapes the string, or displays an underline
  """
  def disp(str, opts \\ [])
  def disp("", opts), do: disp(nil, opts)

  def disp(nil, opts) do
    if Keyword.get(opts, :underline, false) do
      "\\uline{#{Keyword.get(opts, :filler_text, "Nice Long Blank Line")}}"
    else
      Keyword.get(opts, :filler_text, "(Empty)")
    end
  end

  def disp(str, _opts) do
    escape(pretty_print(str))
  end

  # def pretty_print(%Date{} = date) do
  #   Timex.Format.DateTime.Formatter.format!(date, "{D} {Mfull} {YYYY}")
  # end

  def pretty_print(x), do: x

  def escape(foo) when not is_binary(foo), do: escape(to_string(foo))

  def escape(""), do: ""
  def escape("\\" <> rest), do: "\\\\" <> escape(rest)
  def escape("{" <> rest), do: "\\{" <> escape(rest)
  def escape("}" <> rest), do: "\\}" <> escape(rest)

  def escape(any) do
    {head, tail} = String.next_grapheme(any)
    head <> escape(tail)
  end
end
