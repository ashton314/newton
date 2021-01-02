defmodule Newton.Problem.Exam do
  use Ecto.Schema
  import Ecto.Changeset

  alias __MODULE__

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "exams" do
    field :barcode, :string
    field :course_code, :string
    field :course_name, :string
    field :exam_date, :string
    field :name, :string
    field :stamp, :string

    many_to_many :questions, Newton.Problem.Question, join_through: "exam_questions", on_replace: :delete

    timestamps()
  end

  @type t :: %__MODULE__{}

  @doc false
  def changeset(exam, attrs) do
    exam
    |> cast(attrs, [:name, :course_code, :course_name, :exam_date, :stamp, :barcode])
    |> validate_required([:name, :course_code, :course_name, :exam_date, :stamp, :barcode])
  end

  @doc false
  def restore_changeset(attrs) do
    %Exam{}
    |> cast(attrs, [:name, :course_code, :course_name, :exam_date, :stamp, :barcode, :inserted_at, :updated_at, :id])
    |> validate_required([:name])
  end

  # Changeset for modifying the many-to-many relation
  @doc false
  def questions_changeset(exam, questions) do
    exam
    |> change()
    |> put_assoc(:questions, questions)
  end
end
