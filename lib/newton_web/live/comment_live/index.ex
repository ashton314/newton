defmodule NewtonWeb.CommentLive.Index do
  use NewtonWeb, :live_view

  alias Newton.Problem
  alias Newton.Problem.Comment

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
    |> assign(:comment, Problem.get_comment!(id))
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
    comment = Problem.get_comment!(id)
    {:ok, _} = Problem.delete_comment(comment)

    {:noreply, assign(socket, :comments, fetch_comments())}
  end

  defp fetch_comments do
    Problem.list_comments()
  end
end
