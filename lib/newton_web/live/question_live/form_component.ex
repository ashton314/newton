defmodule NewtonWeb.QuestionLive.FormComponent do
  use NewtonWeb, :live_component

  import NewtonWeb.IconHelpers

  alias Newton.Problem
  alias Newton.Problem.Answer
  alias NewtonWeb.QuestionLive.TagSuggestion

  @impl true
  def update(
        %{id: id, preview_contents: prev_cont, preview_state: prev_state} = assigns,
        socket
      ) do
    question = Problem.get_question!(id) |> Problem.preload_assocs()

    if is_nil(prev_state) && question.text != "", do: request_render(question)

    {:ok,
     socket
     |> assign(assigns)
     |> assign_new(:changeset, fn -> Problem.change_question(question) end)
     |> assign_new(:answer_changeset, fn -> Answer.changeset(%Answer{}) end)
     |> assign_new(:comments, fn -> question.comments end)
     |> assign_new(:answers, fn -> question.answers end)
     |> assign_new(:preview_contents, fn -> prev_cont end)
     |> assign_new(:preview_state, fn -> prev_state end)}
  end

  def update(%{id: _id, new_tag: new_tag} = assigns, socket) do
    {:ok,
     socket
     |> assign(assigns)
     |> update(:changeset, fn cs ->
       old_tags = Ecto.Changeset.get_field(cs, :tags, []) || []

       Problem.Question.preloaded_changeset(cs, %{
         tags: old_tags ++ [new_tag]
       })
       |> IO.inspect(label: :new_cs)
     end)}
  end

  @impl true
  def handle_event("validate", %{"question" => question_params}, socket) do
    changeset =
      socket.assigns.question
      |> Problem.change_question(question_params)
      |> Map.put(:action, :validate)

    socket = assign(socket, changeset: changeset)

    validated_question = Ecto.Changeset.apply_changes(socket.assigns.changeset)

    request_render(validated_question)

    {:noreply, socket}
  end

  def handle_event("validate-answer", %{"answer" => new_answer}, socket) do
    {:noreply, update(socket, :answer_changeset, fn cs -> Answer.changeset(cs, new_answer) end)}
  end

  def handle_event("append-answer", %{"answer" => new_answer}, socket) do
    answer_cs = Answer.changeset(%Answer{}, new_answer)

    if answer_cs.valid? do
      {:ok, new_answer} =
        Problem.create_answer(Map.put(new_answer, "question_id", socket.assigns.id))

      socket =
        socket
        |> assign(:answer_changeset, Answer.changeset(%Answer{}))
        |> update(:answers, fn answers -> answers ++ [new_answer] end)

      {:noreply, socket}
    else
      {:noreply, assign(socket, :answer_changeset, answer_cs)}
    end
  end

  def handle_event("tag_keyup", val, socket) do
    IO.inspect(val, label: "val")

    {:noreply, socket}
  end

  def handle_event("save", %{"question" => question_params}, socket) do
    save_question(socket, socket.assigns.action, question_params)
  end

  def handle_event("mark-correct", %{"click" => answer_id}, socket) do
    new_answers =
      socket.assigns.answers
      |> Enum.map(fn
        %{id: ^answer_id} = answer -> Problem.update_answer(answer, %{points_marked: 1})
        answer -> Problem.update_answer(answer, %{points_marked: 0})
      end)
      |> Enum.map(fn {:ok, ans} -> ans end)

    {:noreply, assign(socket, :answers, new_answers)}
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
