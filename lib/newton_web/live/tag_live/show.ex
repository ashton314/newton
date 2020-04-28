defmodule NewtonWeb.TagLive.Show do
  use NewtonWeb, :live_view

  alias Newton.Problem

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl true
  def handle_params(%{"id" => id}, _, socket) do
    {:noreply,
     socket
     |> assign(:page_title, page_title(socket.assigns.live_action))
     |> assign(:tag, Problem.get_tag!(id))}
  end

  defp page_title(:show), do: "Show Tag"
  defp page_title(:edit), do: "Edit Tag"
end
