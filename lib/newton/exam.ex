defmodule Newton.Exam do
  @moduledoc """
  Context for exam-related routines.
  """

  import Ecto.Query, warn: false
  import Ecto.Query.API, only: [fragment: 1], warn: false
  alias Newton.Repo

  alias Newton.Problem.Exam

  @doc """
  Returns the list of exams.
  """
  def list_exams do
    Repo.all(Exam)
  end

  @doc """
  Gets a single exam.

  Raises `Ecto.NoResultsError` if the Exam does not exist.
  """
  def get_exam!(id), do: Repo.get!(Exam, id)

  @doc """
  Creates a exam.
  """
  def create_exam(attrs \\ %{}) do
    %Exam{}
    |> Exam.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a exam.

  ## Examples

      iex> update_exam(exam, %{field: new_value})
      {:ok, %Exam{}}

      iex> update_exam(exam, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_exam(%Exam{} = exam, attrs) do
    exam
    |> Exam.changeset(attrs)
    |> Repo.update()
  end

  def update_exam_questions(%Exam{} = exam, new_questions) do
    exam
    |> Repo.preload(:questions)
    |> Exam.questions_changeset(new_questions)
    |> Repo.update()
  end

  @doc """
  Deletes a exam.

  ## Examples

      iex> delete_exam(exam)
      {:ok, %Exam{}}

      iex> delete_exam(exam)
      {:error, %Ecto.Changeset{}}

  """
  def delete_exam(%Exam{} = exam) do
    Repo.delete(exam)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking exam changes.
  """
  def change_exam(%Exam{} = exam, attrs \\ %{}) do
    Exam.changeset(exam, attrs)
  end
end
