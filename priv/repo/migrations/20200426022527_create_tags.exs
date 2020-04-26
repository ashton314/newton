defmodule Newton.Repo.Migrations.CreateTags do
  use Ecto.Migration

  def change do
    create table(:tags, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :name, :string
      add :color, :string
      add :class_id, references(:classes, on_delete: :nothing, type: :binary_id)

      timestamps()
    end

    create index(:tags, [:class_id])
  end
end
