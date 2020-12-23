defmodule Newton.Repo.Migrations.AddPointsColumn do
  use Ecto.Migration

  def change do
    alter table(:questions) do
      add :points, :integer, default: 1
    end
  end
end
