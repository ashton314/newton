defmodule NewtonWeb.QuestionLiveTest do
  use NewtonWeb.ConnCase

  import Phoenix.LiveViewTest

  alias Newton.Problem

  @create_attrs %{
    text: "some text",
    type: "free_response",
    name: "some name"
  }
  @invalid_attrs %{text: ""}

  defp fixture(:question) do
    {:ok, question} = Problem.create_question(@create_attrs)
    question
  end

  defp create_question(_) do
    question = fixture(:question)
    %{question: question}
  end

  describe "Index" do
    setup [:create_question]

    test "lists all questions", %{conn: conn, question: question} do
      {:ok, _index_live, html} = live(conn, Routes.question_index_path(conn, :index))

      assert html =~ "Questions"
      assert html =~ question.name
    end

    test "saves new question", %{conn: conn} do
      {:ok, index_live, _html} = live(conn, Routes.question_index_path(conn, :index))

      assert index_live |> element("a[alt='New Question']") |> render_click() =~
               "New Question"

      assert_patch(index_live, Routes.question_index_path(conn, :new))

      assert index_live
             |> form("#question-form", question: @invalid_attrs)
             |> render_change() =~ "can&apos;t be blank"

      {:ok, _, html} =
        index_live
        |> form("#question-form", question: @create_attrs)
        |> render_submit()
        |> follow_redirect(conn, Routes.question_index_path(conn, :index))

      assert html =~ "Question updated successfully"
      assert html =~ "some name"
    end

    test "modifying text doesn't blow out tags", %{conn: conn} do
      {:ok, index_live, _html} = live(conn, Routes.question_index_path(conn, :index))

      assert index_live |> element("a[alt='New Question']") |> render_click() =~
               "New Question"

      assert_patch(index_live, Routes.question_index_path(conn, :new))

      # Add the tag
      assert index_live
             |> form("#new-tag-form", new_tag: "foo-tag")
             |> render_submit() =~ "foo-tag"

      # Modify something
      {:ok, _, html} =
        index_live
        |> form("#question-form", question: %{name: "by any other name"})
        |> render_submit()
        |> follow_redirect(conn, Routes.question_index_path(conn, :index))

      assert html =~ "by any other name"
      assert html =~ "foo-tag"
    end
  end
end
