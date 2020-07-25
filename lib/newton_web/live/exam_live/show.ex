defmodule NewtonWeb.ExamLive.Show do
  use NewtonWeb, :live_view

  alias Newton.Problem
  alias NewtonWeb.QuestionLive

  @impl true
  def mount(_params, _session, socket) do
    {:ok, assign(socket, :image_renders, %{})}
  end

  @impl true
  def handle_params(%{"id" => id}, _, socket) do
    exam = Problem.get_exam!(id) |> Newton.Repo.preload([:questions])
    exam_questions = exam.questions
    all_questions = Problem.list_questions()

    Enum.map(all_questions, &request_image_render/1)

    {:noreply,
     socket
     |> assign(:page_title, page_title(socket.assigns.live_action))
     |> assign(:exam, exam)
     |> assign(:exam_questions, exam_questions)
     |> assign(:all_questions, all_questions)}
  end

  defp page_title(:show), do: "Show Exam"
  defp page_title(:edit), do: "Edit Exam"

  def handle_info({:preview_ready, :ok, token}, socket) do
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

  def handle_info({:image_preview_ready, :ok, qid, tok}, socket) do
    socket =
      socket
      |> update(:image_renders, fn r -> Map.put(r, qid, tok) end)

    {:noreply, socket}
  end

  defp request_image_render(question) do
    me = self()

    Problem.Render.render_image_preview(
      question,
      fn
        {:ok, tok} -> send(me, {:image_preview_ready, :ok, question.id, tok})
        {:error, mess} -> IO.inspect(mess, label: "error from rendering question")
      end
    )
  end
end
