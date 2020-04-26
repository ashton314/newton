defmodule NewtonWeb.CommentLive.Index do
  use NewtonWeb, :live_view

  alias Newton.Test
  alias Newton.Test.Comment

  @impl true
  def mount(_params, _session, socket) do
    {:ok, assign(socket, :comments, fetch_comments())}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :edit, %{"id" => id}) do
    socket
    |> assign(:page_title, "Edit Comment")
    |> assign(:comment, Test.get_comment!(id))
  end

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:page_title, "New Comment")
    |> assign(:comment, %Comment{})
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "Listing Comments")
    |> assign(:comment, nil)
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    comment = Test.get_comment!(id)
    {:ok, _} = Test.delete_comment(comment)

    {:noreply, assign(socket, :comments, fetch_comments())}
  end

  defp fetch_comments do
    Test.list_comments()
  end
end
