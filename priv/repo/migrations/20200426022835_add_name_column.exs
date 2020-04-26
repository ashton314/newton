defmodule Newton.Repo.Migrations.AddNameColumn do
  use Ecto.Migration

  def change do
    alter table(:questions) do
      add :name, :string
    end
  end
end
