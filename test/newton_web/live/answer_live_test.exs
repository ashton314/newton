defmodule NewtonWeb.AnswerLiveTest do
  use NewtonWeb.ConnCase

  import Phoenix.LiveViewTest

  alias Newton.Problem

  @create_attrs %{display: true, points_marked: 42, points_unmarked: 42, text: "some text"}
  @update_attrs %{display: false, points_marked: 43, points_unmarked: 43, text: "some updated text"}
  @invalid_attrs %{display: nil, points_marked: nil, points_unmarked: nil, text: nil}

  defp fixture(:answer) do
    {:ok, answer} = Problem.create_answer(@create_attrs)
    answer
  end

  defp create_answer(_) do
    answer = fixture(:answer)
    %{answer: answer}
  end

  describe "Index" do
    setup [:create_answer]

    test "lists all answers", %{conn: conn, answer: answer} do
      {:ok, _index_live, html} = live(conn, Routes.answer_index_path(conn, :index))

      assert html =~ "Listing Answers"
      assert html =~ answer.text
    end

    test "saves new answer", %{conn: conn} do
      {:ok, index_live, _html} = live(conn, Routes.answer_index_path(conn, :index))

      assert index_live |> element("a", "New Answer") |> render_click() =~
        "New Answer"

      assert_patch(index_live, Routes.answer_index_path(conn, :new))

      assert index_live
             |> form("#answer-form", answer: @invalid_attrs)
             |> render_change() =~ "can&apos;t be blank"

      {:ok, _, html} =
        index_live
        |> form("#answer-form", answer: @create_attrs)
        |> render_submit()
        |> follow_redirect(conn, Routes.answer_index_path(conn, :index))

      assert html =~ "Answer created successfully"
      assert html =~ "some text"
    end

    test "updates answer in listing", %{conn: conn, answer: answer} do
      {:ok, index_live, _html} = live(conn, Routes.answer_index_path(conn, :index))

      assert index_live |> element("#answer-#{answer.id} a", "Edit") |> render_click() =~
        "Edit Answer"

      assert_patch(index_live, Routes.answer_index_path(conn, :edit, answer))

      assert index_live
             |> form("#answer-form", answer: @invalid_attrs)
             |> render_change() =~ "can&apos;t be blank"

      {:ok, _, html} =
        index_live
        |> form("#answer-form", answer: @update_attrs)
        |> render_submit()
        |> follow_redirect(conn, Routes.answer_index_path(conn, :index))

      assert html =~ "Answer updated successfully"
      assert html =~ "some updated text"
    end

    test "deletes answer in listing", %{conn: conn, answer: answer} do
      {:ok, index_live, _html} = live(conn, Routes.answer_index_path(conn, :index))

      assert index_live |> element("#answer-#{answer.id} a", "Delete") |> render_click()
      refute has_element?(index_live, "#answer-#{answer.id}")
    end
  end

  describe "Show" do
    setup [:create_answer]

    test "displays answer", %{conn: conn, answer: answer} do
      {:ok, _show_live, html} = live(conn, Routes.answer_show_path(conn, :show, answer))

      assert html =~ "Show Answer"
      assert html =~ answer.text
    end

    test "updates answer within modal", %{conn: conn, answer: answer} do
      {:ok, show_live, _html} = live(conn, Routes.answer_show_path(conn, :show, answer))

      assert show_live |> element("a", "Edit") |> render_click() =~
        "Edit Answer"

      assert_patch(show_live, Routes.answer_show_path(conn, :edit, answer))

      assert show_live
             |> form("#answer-form", answer: @invalid_attrs)
             |> render_change() =~ "can&apos;t be blank"

      {:ok, _, html} =
        show_live
        |> form("#answer-form", answer: @update_attrs)
        |> render_submit()
        |> follow_redirect(conn, Routes.answer_show_path(conn, :show, answer))

      assert html =~ "Answer updated successfully"
      assert html =~ "some updated text"
    end
  end
end
