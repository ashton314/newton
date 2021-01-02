defmodule Newton.Problem.Question do
  use Ecto.Schema
  import Ecto.Changeset
  alias Newton.Problem

  alias __MODULE__

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "questions" do
    field :archived, :boolean, default: false
    field :last_edit_hash, :string
    field :tags, {:array, :string}
    field :text, :string
    field :type, :string
    field :name, :string
    field :points, :integer, default: 1
    field :class_id, :binary_id
    field :ref_book, :string
    field :ref_chapter, :string
    field :ref_section, :string

    has_many :answers, Problem.Answer
    has_many :comments, Problem.Comment

    timestamps()
  end

  @safe_fields [:name, :text, :tags, :type, :last_edit_hash, :archived, :ref_chapter, :ref_section]

  @doc false
  def changeset(question, attrs) do
    question
    |> cast(attrs, @safe_fields)
    |> validate_required([:text, :type, :name])
    |> validate_inclusion(:type, ~w(multiple_choice free_response fill_in_blank))
  end

  # Assumes the associations have been preloaded
  @doc false
  def preloaded_changeset(question, attrs) do
    question
    |> changeset(attrs)
    |> cast_assoc(:answers, with: &Problem.Answer.changeset/2)
    |> cast_assoc(:comments, with: &Problem.Comment.changeset/2)
  end

  # used for inserting direclty from a backup
  def restore_changeset(attrs) do
    %Question{}
    |> cast(attrs, @safe_fields ++ ~w(id inserted_at updated_at)a)
    |> cast_assoc(:answers, with: &Problem.Answer.restore_changeset/2)
    |> cast_assoc(:comments, with: &Problem.Comment.restore_changeset/2)
  end
end
