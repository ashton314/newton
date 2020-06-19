defmodule NewtonWeb.ExamLive.Index do
  use NewtonWeb, :live_view

  import NewtonWeb.IconHelpers

  alias Newton.Problem
  alias Newton.Problem.Exam

  @impl true
  def mount(_params, _session, socket) do
    {:ok, assign(socket, :exams, list_exams())}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :edit, %{"id" => id}) do
    socket
    |> assign(:page_title, "Edit Exam")
    |> assign(:exam, Problem.get_exam!(id))
  end

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:page_title, "New Exam")
    |> assign(:exam, %Exam{})
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "Listing Exams")
    |> assign(:exam, nil)
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    exam = Problem.get_exam!(id)
    {:ok, _} = Problem.delete_exam(exam)

    {:noreply, assign(socket, :exams, list_exams())}
  end

  defp list_exams do
    Problem.list_exams()
  end
end
