defmodule NewtonWeb.ExamLiveTest do
  use NewtonWeb.ConnCase

  import Phoenix.LiveViewTest

  alias Newton.Problem

  @create_attrs %{barcode: "some barcode", course_code: "some course_code", course_name: "some course_name", exam_date: "some exam_date", name: "some name", stamp: "some stamp"}
  @update_attrs %{barcode: "some updated barcode", course_code: "some updated course_code", course_name: "some updated course_name", exam_date: "some updated exam_date", name: "some updated name", stamp: "some updated stamp"}
  @invalid_attrs %{barcode: nil, course_code: nil, course_name: nil, exam_date: nil, name: nil, stamp: nil}

  defp fixture(:exam) do
    {:ok, exam} = Problem.create_exam(@create_attrs)
    exam
  end

  defp create_exam(_) do
    exam = fixture(:exam)
    %{exam: exam}
  end

  describe "Index" do
    setup [:create_exam]

    test "lists all exams", %{conn: conn, exam: exam} do
      {:ok, _index_live, html} = live(conn, Routes.exam_index_path(conn, :index))

      assert html =~ "Listing Exams"
      assert html =~ exam.barcode
    end

    @tag :skip
    test "saves new exam", %{conn: conn} do
      {:ok, index_live, _html} = live(conn, Routes.exam_index_path(conn, :index))

      assert index_live |> element("a", "New Exam") |> render_click() =~
               "New Exam"

      assert_patch(index_live, Routes.exam_index_path(conn, :new))

      assert index_live
             |> form("#exam-form", exam: @invalid_attrs)
             |> render_change() =~ "can&apos;t be blank"

      {:ok, _, html} =
        index_live
        |> form("#exam-form", exam: @create_attrs)
        |> render_submit()
        |> follow_redirect(conn, Routes.exam_index_path(conn, :index))

      assert html =~ "Exam created successfully"
      assert html =~ "some barcode"
    end

    test "updates exam in listing", %{conn: conn, exam: exam} do
      {:ok, index_live, _html} = live(conn, Routes.exam_index_path(conn, :index))

      assert index_live |> element("#exam-#{exam.id} a", "Edit") |> render_click() =~
               "Edit Exam"

      assert_patch(index_live, Routes.exam_index_path(conn, :edit, exam))

      assert index_live
             |> form("#exam-form", exam: @invalid_attrs)
             |> render_change() =~ "can&apos;t be blank"

      {:ok, _, html} =
        index_live
        |> form("#exam-form", exam: @update_attrs)
        |> render_submit()
        |> follow_redirect(conn, Routes.exam_index_path(conn, :index))

      assert html =~ "Exam updated successfully"
      assert html =~ "some updated barcode"
    end

    test "deletes exam in listing", %{conn: conn, exam: exam} do
      {:ok, index_live, _html} = live(conn, Routes.exam_index_path(conn, :index))

      assert index_live |> element("#exam-#{exam.id} a", "Delete") |> render_click()
      refute has_element?(index_live, "#exam-#{exam.id}")
    end
  end

  describe "Show" do
    setup [:create_exam]

    test "displays exam", %{conn: conn, exam: exam} do
      {:ok, _show_live, html} = live(conn, Routes.exam_show_path(conn, :show, exam))

      assert html =~ "Show Exam"
      assert html =~ exam.barcode
    end

    @tag :skip
    test "updates exam within modal", %{conn: conn, exam: exam} do
      {:ok, show_live, _html} = live(conn, Routes.exam_show_path(conn, :show, exam))

      assert show_live |> element("a", "Edit") |> render_click() =~
               "Edit Exam"

      assert_patch(show_live, Routes.exam_show_path(conn, :edit, exam))

      assert show_live
             |> form("#exam-form", exam: @invalid_attrs)
             |> render_change() =~ "can&apos;t be blank"

      {:ok, _, html} =
        show_live
        |> form("#exam-form", exam: @update_attrs)
        |> render_submit()
        |> follow_redirect(conn, Routes.exam_show_path(conn, :show, exam))

      assert html =~ "Exam updated successfully"
      assert html =~ "some updated barcode"
    end
  end
end
