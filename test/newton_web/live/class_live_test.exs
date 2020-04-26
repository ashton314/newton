defmodule NewtonWeb.ClassLiveTest do
  use NewtonWeb.ConnCase

  import Phoenix.LiveViewTest

  alias Newton.Department

  @create_attrs %{name: "some name"}
  @update_attrs %{name: "some updated name"}
  @invalid_attrs %{name: nil}

  defp fixture(:class) do
    {:ok, class} = Department.create_class(@create_attrs)
    class
  end

  defp create_class(_) do
    class = fixture(:class)
    %{class: class}
  end

  describe "Index" do
    setup [:create_class]

    test "lists all classes", %{conn: conn, class: class} do
      {:ok, _index_live, html} = live(conn, Routes.class_index_path(conn, :index))

      assert html =~ "Listing Classes"
      assert html =~ class.name
    end

    test "saves new class", %{conn: conn} do
      {:ok, index_live, _html} = live(conn, Routes.class_index_path(conn, :index))

      assert index_live |> element("a", "New Class") |> render_click() =~
        "New Class"

      assert_patch(index_live, Routes.class_index_path(conn, :new))

      assert index_live
             |> form("#class-form", class: @invalid_attrs)
             |> render_change() =~ "can&apos;t be blank"

      {:ok, _, html} =
        index_live
        |> form("#class-form", class: @create_attrs)
        |> render_submit()
        |> follow_redirect(conn, Routes.class_index_path(conn, :index))

      assert html =~ "Class created successfully"
      assert html =~ "some name"
    end

    test "updates class in listing", %{conn: conn, class: class} do
      {:ok, index_live, _html} = live(conn, Routes.class_index_path(conn, :index))

      assert index_live |> element("#class-#{class.id} a", "Edit") |> render_click() =~
        "Edit Class"

      assert_patch(index_live, Routes.class_index_path(conn, :edit, class))

      assert index_live
             |> form("#class-form", class: @invalid_attrs)
             |> render_change() =~ "can&apos;t be blank"

      {:ok, _, html} =
        index_live
        |> form("#class-form", class: @update_attrs)
        |> render_submit()
        |> follow_redirect(conn, Routes.class_index_path(conn, :index))

      assert html =~ "Class updated successfully"
      assert html =~ "some updated name"
    end

    test "deletes class in listing", %{conn: conn, class: class} do
      {:ok, index_live, _html} = live(conn, Routes.class_index_path(conn, :index))

      assert index_live |> element("#class-#{class.id} a", "Delete") |> render_click()
      refute has_element?(index_live, "#class-#{class.id}")
    end
  end

  describe "Show" do
    setup [:create_class]

    test "displays class", %{conn: conn, class: class} do
      {:ok, _show_live, html} = live(conn, Routes.class_show_path(conn, :show, class))

      assert html =~ "Show Class"
      assert html =~ class.name
    end

    test "updates class within modal", %{conn: conn, class: class} do
      {:ok, show_live, _html} = live(conn, Routes.class_show_path(conn, :show, class))

      assert show_live |> element("a", "Edit") |> render_click() =~
        "Edit Class"

      assert_patch(show_live, Routes.class_show_path(conn, :edit, class))

      assert show_live
             |> form("#class-form", class: @invalid_attrs)
             |> render_change() =~ "can&apos;t be blank"

      {:ok, _, html} =
        show_live
        |> form("#class-form", class: @update_attrs)
        |> render_submit()
        |> follow_redirect(conn, Routes.class_show_path(conn, :show, class))

      assert html =~ "Class updated successfully"
      assert html =~ "some updated name"
    end
  end
end
