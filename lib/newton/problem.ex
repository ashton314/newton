defmodule Newton.Problem do
  @moduledoc """
  The Problem context.
  """

  import Ecto.Query, warn: false
  import Ecto.Query.API, only: [fragment: 1], warn: false
  alias Newton.Repo

  alias __MODULE__
  alias Newton.Problem.Question
  alias Newton.QuestionPage

  def preload_assocs(%Question{} = q, opts \\ []) do
    Repo.preload(q, [:answers, :comments], opts)
  end

  @doc """
  Returns the list of questions.
  """
  def list_questions do
    Repo.all(Question)
  end

  @doc """
  The Big Kahuna: this function takes a `QuestionPage` struct and
  returns a list of `Question` structs along with handles to the next
  and previous pages.
  """
  def paged_questions(%QuestionPage{query: query, page: page, page_length: page_length}) do
    offset = page * page_length

    full_query = from(q in Question)

    # Add tags to the search
    full_query =
      Enum.reduce(query.tags, full_query, fn tag, q_acc ->
        from(q in q_acc, where: fragment("? = ANY (?)", ^tag, q.tags))
      end)

    # Add words to the search
    full_query =
      Enum.reduce(query.normal, full_query, fn word, q_acc ->
        like_query = escape_like_query("%#{word}%")
        from(q in q_acc, where: ilike(q.text, ^like_query))
      end)

    # Peel off the first reference for the first "where"
    {full_query, rest_refs} =
      case query.refs do
        [] ->
          {full_query, []}

        [%{chapter: cpt, section: sec} | rest] ->
          # We put the keywords up here so we get the grouping right
          filters = [ref_chapter: "#{cpt}", ref_section: "#{sec}"]
          {from(q in full_query, where: ^filters), rest}

        [%{chapter: cpt} | rest] ->
          {from(q in full_query, where: q.ref_chapter == ^"#{cpt}"), rest}
      end

    full_query =
      Enum.reduce(rest_refs, full_query, fn
        %{chapter: cpt, section: sec}, q_acc ->
          # We put the keywords up here so we get the grouping right
          filters = [ref_chapter: "#{cpt}", ref_section: "#{sec}"]
          from(q in q_acc, or_where: ^filters)

        %{chapter: cpt}, q_acc ->
          from(q in q_acc, or_where: q.ref_chapter == ^"#{cpt}")
      end)

    total_count =
      from(p in full_query, select: count())
      |> Repo.one()

    paginated_query = from(q in full_query, limit: ^page_length, offset: ^offset)

    questions =
      paginated_query
      |> Repo.all()

    %{
      results: questions,
      next_page:
        if(offset + length(questions) >= total_count,
          do: nil,
          else: %QuestionPage{query: query, page: page + 1, page_length: page_length}
        ),
      previous_page:
        if(page == 0,
          do: nil,
          else: %QuestionPage{query: query, page: page - 1, page_length: page_length}
        ),
      total_count: total_count
    }
  end

  @doc """
  Escapes a string that gets passed to `ilike/2`.
  """
  @spec escape_like_query(String.t()) :: String.t()
  def escape_like_query(str) do
    Regex.replace(~r/[\\|+*_?{}_()\[\]]/, str, &"\\#{&1}")
  end

  @doc """
  Returns a list of questions matching a query string
  """
  def list_questions(_query_string) do
    Repo.all(Question)
  end

  @doc """
  Returns a list of all tags in use in the project.
  """
  def list_tags_from_questions do
    list_questions()
    |> Enum.reduce(:sets.new(), fn %Question{tags: tags}, set ->
      Enum.reduce(tags || [], set, fn t, s -> :sets.add_element(t, s) end)
    end)
    |> :sets.to_list()
  end

  @doc """
  Gets a single question.

  Raises `Ecto.NoResultsError` if the Question does not exist.

  """
  def get_question!(id), do: Repo.get!(Question, id)

  @doc """
  Creates a question.
  """
  def create_question(attrs \\ %{}) do
    %Question{}
    |> Question.preloaded_changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a question.
  """
  def update_question(%Question{} = question, attrs) do
    result =
      question
      |> Repo.preload([:answers, :comments])
      |> Question.preloaded_changeset(attrs)
      |> Repo.update()

    case result do
      {:ok, %Question{}} ->
        Problem.Render.delete_image_preview(question)
        result

      _ ->
        result
    end
  end

  @doc """
  Deletes a question.
  """
  def delete_question(%Question{} = question) do
    Repo.delete(question)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking question changes.
  """
  def change_question(%Question{} = question, attrs \\ %{}) do
    question
    |> Repo.preload([:answers, :comments])
    |> Question.preloaded_changeset(attrs)
  end

  alias Newton.Problem.Answer

  @doc """
  Returns the list of answers.
  """
  def list_answers do
    Repo.all(Answer)
  end

  @doc """
  Gets a single answer.

  Raises `Ecto.NoResultsError` if the Answer does not exist.

  ## Examples

      iex> get_answer!(123)
      %Answer{}

      iex> get_answer!(456)
      ** (Ecto.NoResultsError)

  """
  def get_answer!(id), do: Repo.get!(Answer, id)

  @doc """
  Creates a answer.

  ## Examples

      iex> create_answer(%{field: value})
      {:ok, %Answer{}}

      iex> create_answer(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_answer(attrs \\ %{}) do
    %Answer{}
    |> Answer.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a answer.

  ## Examples

      iex> update_answer(answer, %{field: new_value})
      {:ok, %Answer{}}

      iex> update_answer(answer, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_answer(%Answer{} = answer, attrs) do
    answer
    |> Answer.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a answer.

  ## Examples

      iex> delete_answer(answer)
      {:ok, %Answer{}}

      iex> delete_answer(answer)
      {:error, %Ecto.Changeset{}}

  """
  def delete_answer(%Answer{} = answer) do
    Repo.delete(answer)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking answer changes.

  ## Examples

      iex> change_answer(answer)
      %Ecto.Changeset{data: %Answer{}}

  """
  def change_answer(%Answer{} = answer, attrs \\ %{}) do
    Answer.changeset(answer, attrs)
  end

  alias Newton.Problem.Comment

  @doc """
  Returns the list of comments.

  ## Examples

      iex> list_comments()
      [%Comment{}, ...]

  """
  def list_comments do
    Repo.all(Comment)
  end

  @doc """
  Gets a single comment.

  Raises `Ecto.NoResultsError` if the Comment does not exist.

  ## Examples

      iex> get_comment!(123)
      %Comment{}

      iex> get_comment!(456)
      ** (Ecto.NoResultsError)

  """
  def get_comment!(id), do: Repo.get!(Comment, id)

  @doc """
  Creates a comment.

  ## Examples

      iex> create_comment(%{field: value})
      {:ok, %Comment{}}

      iex> create_comment(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_comment(attrs \\ %{}) do
    %Comment{}
    |> Comment.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a comment.

  ## Examples

      iex> update_comment(comment, %{field: new_value})
      {:ok, %Comment{}}

      iex> update_comment(comment, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_comment(%Comment{} = comment, attrs) do
    comment
    |> Comment.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a comment.

  ## Examples

      iex> delete_comment(comment)
      {:ok, %Comment{}}

      iex> delete_comment(comment)
      {:error, %Ecto.Changeset{}}

  """
  def delete_comment(%Comment{} = comment) do
    Repo.delete(comment)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking comment changes.

  ## Examples

      iex> change_comment(comment)
      %Ecto.Changeset{data: %Comment{}}

  """
  def change_comment(%Comment{} = comment, attrs \\ %{}) do
    Comment.changeset(comment, attrs)
  end

  alias Newton.Problem.Tag

  @doc """
  Returns the list of tags.

  ## Examples

      iex> list_tags()
      [%Tag{}, ...]

  """
  def list_tags do
    Repo.all(Tag)
  end

  @doc """
  Gets a single tag.

  Raises `Ecto.NoResultsError` if the Tag does not exist.

  ## Examples

      iex> get_tag!(123)
      %Tag{}

      iex> get_tag!(456)
      ** (Ecto.NoResultsError)

  """
  def get_tag!(id), do: Repo.get!(Tag, id)

  @doc """
  Creates a tag.

  ## Examples

      iex> create_tag(%{field: value})
      {:ok, %Tag{}}

      iex> create_tag(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_tag(attrs \\ %{}) do
    %Tag{}
    |> Tag.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a tag.

  ## Examples

      iex> update_tag(tag, %{field: new_value})
      {:ok, %Tag{}}

      iex> update_tag(tag, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_tag(%Tag{} = tag, attrs) do
    tag
    |> Tag.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a tag.

  ## Examples

      iex> delete_tag(tag)
      {:ok, %Tag{}}

      iex> delete_tag(tag)
      {:error, %Ecto.Changeset{}}

  """
  def delete_tag(%Tag{} = tag) do
    Repo.delete(tag)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking tag changes.

  ## Examples

      iex> change_tag(tag)
      %Ecto.Changeset{data: %Tag{}}

  """
  def change_tag(%Tag{} = tag, attrs \\ %{}) do
    Tag.changeset(tag, attrs)
  end
end
