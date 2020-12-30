defmodule Newton.Problem.Comment do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "comments" do
    field :resolved, :boolean, default: false
    field :text, :string
    field :question_id, :binary_id

    timestamps()
  end

  @doc false
  def changeset(comment, attrs) do
    comment
    |> cast(attrs, [:text, :resolved])
    |> validate_required([:text, :resolved])
  end
end
