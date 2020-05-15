defmodule NewtonWeb.QuestionLive.FormComponent do
  use NewtonWeb, :live_component

  alias Newton.Problem

  @impl true
  def update(
        %{id: :new, preview_contents: prev_cont, preview_state: prev_state} = assigns,
        socket
      ) do
    # This blows up and just keeps inserting questions into the DB when it tries to render a preview---yikes!
    {:ok, question} =
      Problem.create_question(%{
        text: "Math is $\\int\\cup\\prod$",
        # name: "New question",
        type: "multiple_choice"
      })

    question = Problem.preload_assocs(question)

    {:ok,
     socket
     |> assign(assigns)
     |> assign(:changeset, Map.get(socket.assigns, :changeset, Problem.change_question(question)))
     |> assign(:comments, question.comments)
     |> assign(:answers, question.answers)
     |> assign(:preview_contents, prev_cont)
     |> assign(:preview_state, prev_state)}
  end

  def update(
        %{id: id, preview_contents: prev_cont, preview_state: prev_state} = assigns,
        socket
      ) do
    question = Problem.get_question!(id) |> Problem.preload_assocs()

    # if is_nil(prev_state) && question.text != "", do: request_render(question)

    {:ok,
     socket
     |> assign(assigns)
     |> assign(:changeset, Map.get(socket.assigns, :changeset, Problem.change_question(question)))
     |> assign(:comments, question.comments)
     |> assign(:answers, question.answers)
     |> assign(:preview_contents, prev_cont)
     |> assign(:preview_state, prev_state)}
  end

  @impl true
  def handle_event("validate", %{"question" => question_params}, socket) do
    changeset =
      socket.assigns.question
      |> Problem.change_question(question_params)
      |> Map.put(:action, :validate)

    socket = assign(socket, changeset: changeset)

    validated_question = Ecto.Changeset.apply_changes(socket.assigns.changeset)
    IO.inspect(validated_question, label: "validated_question")

    request_render(validated_question)

    {:noreply, socket}
  end

  def handle_event("save", %{"question" => question_params}, socket) do
    save_question(socket, socket.assigns.action, question_params)
  end

  defp request_render(question) do
    me = self()

    Problem.Render.render_question_preview(
      question,
      fn
        {:ok, tok} -> send(me, {:preview_ready, :ok, tok})
        {:error, mess} -> send(me, {:preview_ready, :error, mess})
      end
    )
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
