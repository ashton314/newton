defmodule Newton.ExamTest do
  use Newton.DataCase, async: true

  describe "exams" do
    alias Newton.Problem.Exam

    @valid_attrs %{
      barcode: "some barcode",
      course_code: "some course_code",
      course_name: "some course_name",
      exam_date: "some exam_date",
      name: "some name",
      stamp: "some stamp"
    }
    @update_attrs %{
      barcode: "some updated barcode",
      course_code: "some updated course_code",
      course_name: "some updated course_name",
      exam_date: "some updated exam_date",
      name: "some updated name",
      stamp: "some updated stamp"
    }
    @invalid_attrs %{barcode: nil, course_code: nil, course_name: nil, exam_date: nil, name: nil, stamp: nil}

    def exam_fixture(attrs \\ %{}) do
      {:ok, exam} =
        attrs
        |> Enum.into(@valid_attrs)
        |> Newton.Exam.create_exam()

      exam
    end

    test "list_exams/0 returns all exams" do
      exam = exam_fixture()
      assert Newton.Exam.list_exams() == [exam]
    end

    test "get_exam!/1 returns the exam with given id" do
      exam = exam_fixture()
      assert Newton.Exam.get_exam!(exam.id) == exam
    end

    test "create_exam/1 with valid data creates a exam" do
      assert {:ok, %Exam{} = exam} = Newton.Exam.create_exam(@valid_attrs)
      assert exam.barcode == "some barcode"
      assert exam.course_code == "some course_code"
      assert exam.course_name == "some course_name"
      assert exam.exam_date == "some exam_date"
      assert exam.name == "some name"
      assert exam.stamp == "some stamp"
    end

    test "create_exam/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Newton.Exam.create_exam(@invalid_attrs)
    end

    test "update_exam/2 with valid data updates the exam" do
      exam = exam_fixture()
      assert {:ok, %Exam{} = exam} = Newton.Exam.update_exam(exam, @update_attrs)
      assert exam.barcode == "some updated barcode"
      assert exam.course_code == "some updated course_code"
      assert exam.course_name == "some updated course_name"
      assert exam.exam_date == "some updated exam_date"
      assert exam.name == "some updated name"
      assert exam.stamp == "some updated stamp"
    end

    test "update_exam/2 with invalid data returns error changeset" do
      exam = exam_fixture()
      assert {:error, %Ecto.Changeset{}} = Newton.Exam.update_exam(exam, @invalid_attrs)
      assert exam == Newton.Exam.get_exam!(exam.id)
    end

    test "delete_exam/1 deletes the exam" do
      exam = exam_fixture()
      assert {:ok, %Exam{}} = Newton.Exam.delete_exam(exam)
      assert_raise Ecto.NoResultsError, fn -> Newton.Exam.get_exam!(exam.id) end
    end

    test "change_exam/1 returns a exam changeset" do
      exam = exam_fixture()
      assert %Ecto.Changeset{} = Newton.Exam.change_exam(exam)
    end
  end
end
