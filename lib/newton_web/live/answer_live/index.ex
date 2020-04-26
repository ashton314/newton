defmodule NewtonWeb.AnswerLive.Index do
  use NewtonWeb, :live_view

  alias Newton.Test
  alias Newton.Test.Answer

  @impl true
  def mount(_params, _session, socket) do
    {:ok, assign(socket, :answers, fetch_answers())}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :edit, %{"id" => id}) do
    socket
    |> assign(:page_title, "Edit Answer")
    |> assign(:answer, Test.get_answer!(id))
  end

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:page_title, "New Answer")
    |> assign(:answer, %Answer{})
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "Listing Answers")
    |> assign(:answer, nil)
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    answer = Test.get_answer!(id)
    {:ok, _} = Test.delete_answer(answer)

    {:noreply, assign(socket, :answers, fetch_answers())}
  end

  defp fetch_answers do
    Test.list_answers()
  end
end
