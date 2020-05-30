defmodule Newton.Repo.Migrations.CreateQuestions do
  use Ecto.Migration

  def change do
    create table(:questions, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :text, :string
      add :tags, {:array, :string}
      add :type, :string
      add :last_edit_hash, :string
      add :archived, :boolean, default: false, null: false
      add :class_id, references(:classes, on_delete: :nothing, type: :binary_id)
      add :ref_book, :string
      add :ref_chapter, :string
      add :ref_section, :string

      timestamps()
    end

    create index(:questions, [:class_id])
  end
end
