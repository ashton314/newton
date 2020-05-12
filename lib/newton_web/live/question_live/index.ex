defmodule NewtonWeb.QuestionLive.Index do
  use NewtonWeb, :live_view

  alias Newton.Problem
  alias Newton.Problem.Question
  alias NewtonWeb.QuestionLive.QuestionCard

  @impl true
  def mount(_params, _session, socket) do
    {:ok, assign(socket, :questions, fetch_questions())}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :edit, %{"id" => id}) do
    socket
    |> assign(:preview_state, nil)
    |> assign(:preview_contents, nil)
    |> assign(:page_title, "Edit Question")
    |> assign(:question, Problem.get_question!(id))
  end

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:preview_state, nil)
    |> assign(:preview_contents, nil)
    |> assign(:page_title, "New Question")
    |> assign(:question, %Question{})
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "Listing Questions")
    |> assign(:question, nil)
  end

  # Handle edits
  @impl true
  def handle_info({:preview_ready, :ok, token}, socket) do
    IO.inspect(token, label: "[handle_info {:preview_ready}] token")

    send_update(NewtonWeb.QuestionLive.FormComponent,
      id: socket.assigns.question.id,
      preview_contents: token,
      preview_state: :ok
    )

    {:noreply, socket}
  end

  def handle_info({:preview_ready, :error, err_message}, socket) do
    socket =
      socket
      |> assign(:preview_state, :error)
      |> assign(:preview_contents, err_message)

    {:noreply, socket}
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    question = Problem.get_question!(id)
    {:ok, _} = Problem.delete_question(question)

    {:noreply, assign(socket, :questions, fetch_questions())}
  end

  defp fetch_questions do
    Problem.list_questions()
  end
end
