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

  EEx.function_from_file(
    :defp,
    :layout_question_image_preview,
    "lib/newton/problem/templates/question_image_preview.latex.eex",
    [:contents]
  )


  @spec delete_image_preview(question :: Question.t()) :: :ok
  def delete_image_preview(%Question{id: q_id}) do
    case LatexRenderer.retrieve_from_token(q_id) do
      {:error, :bad_token} -> :ok
      {:ok, path} ->
        dir =
          Path.split(path)
          |> List.delete_at(-1)
          |> Path.join()

        # I *could* use File.rm_rf!, but this is a little safer
        if File.exists?(Path.join(dir, "question_preview.tex")) do
          Path.wildcard(Path.join(dir, "question_preview*"))
          |> Enum.map(&File.rm!/1)

          File.rmdir!(dir)
          :ok
        else
          Logger.debug("File not found; returning :ok anyway")
          :ok
        end
    end
  end

  @doc """
  Render a preview of the question as an image.

  `callback` should be a function like:

      {:ok, token} | {:error, String.t()} -> any()

  `callback` will be invoked after the function has finished. We use
  this in the program to send a message to the LiveView process
  waiting for the preview to finish rendering.
  """
  def render_image_preview(%Question{id: q_id} = question, callback) do
    layout_question_image_preview(question.text)
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
