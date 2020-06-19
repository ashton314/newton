defmodule Newton.Repo.Migrations.CreateExams do
  use Ecto.Migration

  def change do
    create table(:exams, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :name, :string
      add :course_code, :string
      add :course_name, :string
      add :exam_date, :string
      add :stamp, :string
      add :barcode, :string

      timestamps()
    end

  end
end
