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
     |> assign_new(:question, fn -> question end)
     |> assign_new(:changeset, fn -> Problem.change_question(question) end)
     |> assign_new(:answer_changeset, fn -> Answer.changeset(%Answer{}) end)
     |> assign_new(:comments, fn -> question.comments end)
     |> assign_new(:answers, fn -> question.answers end)
     |> assign_new(:preview_contents, fn -> prev_cont end)
     |> assign_new(:preview_state, fn -> prev_state end)
     |> assign_new(:tag_suggestions, fn -> [] end)
     |> assign_new(:tags, fn -> question.tags || [] end)}
  end

  @impl true
  def handle_event("validate", %{"question" => question_params}, socket) do
    changeset =
      socket.assigns.question
      |> Problem.Question.preloaded_changeset(question_params)
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
      {:ok, new_answer} = Problem.create_answer(Map.put(new_answer, "question_id", socket.assigns.id))

      socket =
        socket
        |> assign(:answer_changeset, Answer.changeset(%Answer{}))
        |> update(:answers, fn answers -> answers ++ [new_answer] end)

      validated_question = Ecto.Changeset.apply_changes(socket.assigns.changeset)
      request_render(validated_question)

      {:noreply, socket}
    else
      {:noreply, assign(socket, :answer_changeset, answer_cs)}
    end
  end

  def handle_event("mark-correct", %{"click" => answer_id}, socket) do
    new_answers =
      socket.assigns.answers
      |> Enum.map(fn
        %{id: ^answer_id} = answer -> Problem.update_answer(answer, %{points_marked: 1})
        answer -> Problem.update_answer(answer, %{points_marked: 0})
      end)
      |> Enum.map(fn {:ok, ans} -> ans end)

    validated_question = Ecto.Changeset.apply_changes(socket.assigns.changeset)
    request_render(validated_question)

    {:noreply, assign(socket, :answers, new_answers)}
  end

  def handle_event("delete-answer", %{"click" => answer_id}, socket) do
    answer = Enum.find(socket.assigns.answers, &(&1.id == answer_id))
    Problem.delete_answer(answer)

    validated_question = Ecto.Changeset.apply_changes(socket.assigns.changeset)
    request_render(validated_question)

    {:noreply, update(socket, :answers, fn answers -> Enum.reject(answers, &(&1.id == answer_id)) end)}
  end

  def handle_event("suggest-tags", %{"new_tag" => new_tag}, socket) do
    tag = new_tag
    all_tags = Problem.list_tags_from_questions()

    matches = Enum.filter(all_tags, fn t -> String.contains?(t, tag) end)

    socket =
      socket
      |> assign(:tag_suggestions, matches)

    {:noreply, socket}
  end

  def handle_event("add-tag", %{"new_tag" => new_tag}, socket) do
    socket =
      socket
      |> assign(:tag_suggestions, [])
      |> update(:tags, fn tags -> tags ++ [new_tag] end)

    {:noreply, socket}
  end

  def handle_event("tag_keyup", _val, socket) do
    {:noreply, socket}
  end

  def handle_event("save", %{"question" => question_params}, socket) do
    save_question(socket, socket.assigns.action, Map.put(question_params, "tags", socket.assigns.tags))
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

  defp save_question(socket, _verb, question_params) do
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
end
