defmodule Newton.Repo.Migrations.CreateComments do
  use Ecto.Migration

  def change do
    create table(:comments, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :text, :string
      add :resolved, :boolean, default: false, null: false
      add :question_id, references(:questions, on_delete: :nothing, type: :binary_id)
      add :user_id, references(:users, on_delete: :nothing, type: :binary_id)

      timestamps()
    end

    create index(:comments, [:question_id])
    create index(:comments, [:user_id])
  end
end
