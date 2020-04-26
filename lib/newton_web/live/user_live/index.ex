defmodule NewtonWeb.UserLive.Index do
  use NewtonWeb, :live_view

  alias Newton.Auth
  alias Newton.Auth.User

  @impl true
  def mount(_params, _session, socket) do
    {:ok, assign(socket, :users, fetch_users())}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :edit, %{"id" => id}) do
    socket
    |> assign(:page_title, "Edit User")
    |> assign(:user, Auth.get_user!(id))
  end

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:page_title, "New User")
    |> assign(:user, %User{})
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "Listing Users")
    |> assign(:user, nil)
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    user = Auth.get_user!(id)
    {:ok, _} = Auth.delete_user(user)

    {:noreply, assign(socket, :users, fetch_users())}
  end

  defp fetch_users do
    Auth.list_users()
  end
end
