defmodule Newton.Repo.Migrations.ChangeStringToText do
  use Ecto.Migration

  def change do
    alter table(:answers) do
      modify :text, :text, from: :string
    end

    alter table(:comments) do
      modify :text, :text, from: :string
    end
  end
end
