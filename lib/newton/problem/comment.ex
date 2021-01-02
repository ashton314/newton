defmodule Newton.Problem.Comment do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  @derive {Jason.Encoder, except: [:__struct__, :__meta__]}
  schema "comments" do
    field :resolved, :boolean, default: false
    field :text, :string
    field :question_id, :binary_id

    timestamps()
  end

  @doc false
  def changeset(comment, attrs \\ %{}) do
    comment
    |> cast(attrs, [:text, :resolved, :question_id])
    |> validate_required([:text])
  end

  @doc false
  def restore_changeset(comment, attrs \\ %{}) do
    comment
    |> cast(attrs, [:text, :resolved, :question_id, :inserted_at, :updated_at, :id])
    |> validate_required([:text])
  end
end
