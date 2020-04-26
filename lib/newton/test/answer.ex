defmodule Newton.Test.Answer do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "answers" do
    field :display, :boolean, default: false
    field :points_marked, :integer
    field :points_unmarked, :integer
    field :text, :string
    field :question_id, :binary_id

    timestamps()
  end

  @doc false
  def changeset(answer, attrs) do
    answer
    |> cast(attrs, [:text, :display, :points_marked, :points_unmarked])
    |> validate_required([:text, :display, :points_marked, :points_unmarked])
  end
end
