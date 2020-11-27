defmodule NewtonWeb.ExamLive.EditQuestions do
  use NewtonWeb, :live_view

  # import NewtonWeb.IconHelpers

  alias Newton.Exam

  @impl true
  def mount(_params, _session, socket) do
    socket =
      socket
      |> assign(:added_questions, [])
      |> assign(:all_questions, [])

    {:ok, socket}
  end

  @impl true
  def handle_params(%{"id" => id}, _, socket) do
    exam = Exam.get_exam!(id) |> Newton.Repo.preload(:questions)

    {:noreply,
     socket
     |> assign(:page_title, page_title(socket.assigns.live_action))
     |> assign(:exam, exam)
     |> assign(:added_questions, exam.questions)}
  end

  defp page_title(:show), do: "Show Exam"
  defp page_title(:edit), do: "Edit Exam"
end
