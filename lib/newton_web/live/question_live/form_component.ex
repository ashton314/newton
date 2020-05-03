defmodule NewtonWeb.QuestionLive.FormComponent do
  use NewtonWeb, :live_component

  alias Newton.Problem

  @impl true
  def update(
        %{question: question, preview_contents: prev_cont, preview_state: prev_state} = assigns,
        socket
      ) do
    changeset = Problem.change_question(question)

    IO.inspect(assigns, label: "assigns in update 1")

    {:ok,
     socket
     |> assign(assigns)
     |> assign(:changeset, changeset)
     |> assign(:preview_contents, prev_cont)
     |> assign(:preview_state, prev_state)}
  end

  def update(%{question: question} = assigns, socket) do
    changeset = Problem.change_question(question)

    IO.inspect(assigns, label: "assigns in update 2")

    {:ok,
     socket
     |> assign(assigns)
     |> assign(:changeset, changeset)
     |> assign(:preview_contents, nil)
     |> assign(:preview_state, nil)}
  end

  @impl true
  def handle_event("validate", %{"question" => question_params}, socket) do
    # changeset =
    #   socket.assigns.question
    #   |> Problem.change_question(question_params)
    #   |> Map.put(:action, :validate)

    # # text = question_params["text"]
    # validated_question = Ecto.Changeset.apply_changes(socket.assigns.changeset)
    # IO.inspect(validated_question, label: "validated_question")

    me = self()

    case Problem.update_question(socket.assigns.question, question_params) do
      {:ok, updated_question} ->
        Problem.Render.render_question_preview(
          updated_question,
          fn
            {:ok, tok} -> send(me, {:preview_ready, :ok, tok})
            {:error, mess} -> send(me, {:preview_ready, :error, mess})
          end
        )

        {:noreply,
         socket
         |> put_flash(:info, "Question updated successfully")}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, :changeset, changeset)}
    end
  end

  def handle_event("save", %{"question" => question_params}, socket) do
    save_question(socket, socket.assigns.action, question_params)
  end

  defp save_question(socket, :edit, question_params) do
    case Problem.update_question(socket.assigns.question, question_params) do
      {:ok, _question} ->
        {:noreply,
         socket
         |> put_flash(:info, "Question updated successfully")
         |> push_redirect(to: socket.assigns.return_to)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, :changeset, changeset)}
    end
  end

  defp save_question(socket, :new, question_params) do
    case Problem.create_question(question_params) do
      {:ok, _question} ->
        {:noreply,
         socket
         |> put_flash(:info, "Question created successfully")
         |> push_redirect(to: socket.assigns.return_to)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, changeset: changeset)}
    end
  end
end
