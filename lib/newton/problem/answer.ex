defmodule Newton.Problem.Answer do
  use Ecto.Schema
  import Ecto.Changeset
  alias Newton.Problem

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  @derive {Jason.Encoder, except: [:__struct__, :__meta__, :question]}
  schema "answers" do
    field :display, :boolean, default: false
    field :points_marked, :integer, default: 0
    field :points_unmarked, :integer, default: 0
    field :text, :string

    belongs_to :question, Problem.Question

    timestamps()
  end

  @doc false
  def changeset(answer, attrs \\ %{}) do
    answer
    |> cast(attrs, [:text, :display, :points_marked, :points_unmarked, :question_id])
    |> validate_required([:text])
  end

  def restore_changeset(answer, attrs \\ %{}) do
    answer
    |> cast(attrs, [:text, :display, :points_marked, :points_unmarked, :question_id, :inserted_at, :updated_at, :id])
    |> validate_required([:text])
  end
end
