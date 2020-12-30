defmodule Newton.Repo.Migrations.DropUsersTable do
  use Ecto.Migration

  def change do
    drop index(:comments, [:user_id])

    alter table(:comments) do
      remove :user_id
    end

    drop table(:users)
  end
end
