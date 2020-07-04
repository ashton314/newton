defmodule Newton.Problem.Exam do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "exams" do
    field :barcode, :string
    field :course_code, :string
    field :course_name, :string
    field :exam_date, :string
    field :name, :string
    field :stamp, :string

    many_to_many :questions, Newton.Problem.Question, join_through: "exam_questions"

    timestamps()
  end

  @doc false
  def changeset(exam, attrs) do
    exam
    |> cast(attrs, [:name, :course_code, :course_name, :exam_date, :stamp, :barcode])
    |> validate_required([:name, :course_code, :course_name, :exam_date, :stamp, :barcode])
  end
end
