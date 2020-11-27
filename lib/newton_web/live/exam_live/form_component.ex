defmodule NewtonWeb.ExamLive.FormComponent do
  use NewtonWeb, :live_component

  alias Newton.Exam

  @impl true
  def update(%{exam: exam} = assigns, socket) do
    changeset = Exam.change_exam(exam)

    {:ok,
     socket
     |> assign(assigns)
     |> assign(:changeset, changeset)}
  end

  @impl true
  def handle_event("validate", %{"exam" => exam_params}, socket) do
    changeset =
      socket.assigns.exam
      |> Exam.change_exam(exam_params)
      |> Map.put(:action, :validate)

    {:noreply, assign(socket, :changeset, changeset)}
  end

  def handle_event("save", %{"exam" => exam_params}, socket) do
    save_exam(socket, socket.assigns.action, exam_params)
  end

  defp save_exam(socket, :edit, exam_params) do
    case Exam.update_exam(socket.assigns.exam, exam_params) do
      {:ok, _exam} ->
        {:noreply,
         socket
         |> put_flash(:info, "Exam updated successfully")
         |> push_redirect(to: socket.assigns.return_to)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, :changeset, changeset)}
    end
  end

  defp save_exam(socket, :new, exam_params) do
    case Exam.create_exam(exam_params) do
      {:ok, _exam} ->
        {:noreply,
         socket
         |> put_flash(:info, "Exam created successfully")
         |> push_redirect(to: socket.assigns.return_to)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, changeset: changeset)}
    end
  end
end
