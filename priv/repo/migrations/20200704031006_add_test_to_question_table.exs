defmodule Newton.Repo.Migrations.AddTestToQuestionTable do
  use Ecto.Migration

  def change do
    create table(:exam_questions) do
      add :exam_id, references(:exams, on_delete: :delete_all, type: :binary_id)
      add :question_id, references(:questions, on_delete: :delete_all, type: :binary_id)
      add :index, :integer
    end
  end
end
