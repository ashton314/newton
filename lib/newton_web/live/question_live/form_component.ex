defmodule NewtonWeb.QuestionLive.FormComponent do
  use NewtonWeb, :live_component

  import NewtonWeb.IconHelpers

  alias Newton.Problem
  alias Newton.Problem.Answer
  alias NewtonWeb.QuestionLive.TagSuggestion

  @sample_tags ~w(math112 math113 derivative integral limit easy medium hard)

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
     |> assign_new(:tag_suggestions, fn -> [] end)}
  end

  @impl true
  def handle_event("validate", %{"question" => question_params}, socket) do
    IO.inspect(question_params, label: "question_params in validate")

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

  def handle_event("suggest-tags", %{"new_tag" => new_tag}, socket) do
    tag = new_tag

    matches = Enum.filter(@sample_tags, fn t -> String.contains?(t, tag) end)

    IO.inspect(matches, label: "matches")

    socket =
      socket
      |> assign(:tag_suggestions, matches)

    {:noreply, socket}
  end

  def handle_event("add-tag", %{"new_tag" => new_tag}, socket) do
    socket =
      socket
      |> assign(:tag_suggestions, [])
      |> update(:changeset, fn cs ->
        IO.inspect(cs, label: "cs")
        old_tags = Ecto.Changeset.get_field(cs, :tags) || []
        new_tags = old_tags ++ [new_tag]
        IO.inspect(new_tags, label: "new_tags")

        Problem.Question.preloaded_changeset(cs, %{tags: new_tags})
        |> IO.inspect(label: "new changest")
      end)

    {:noreply, socket}
  end

  def handle_event("tag_keyup", val, socket) do
    IO.inspect(val, label: "val")

    {:noreply, socket}
  end

  def handle_event("save", %{"question" => question_params}, socket) do
    IO.inspect(question_params, label: "question_params after save")
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

  defp save_question(socket, _verb, question_params) do
    case Problem.update_question(
           Map.put(socket.assigns.changeset, :action, :update),
           question_params
         ) do
      {:ok, _question} ->
        {:noreply,
         socket
         |> put_flash(:info, "Question updated successfully")
         |> push_redirect(to: socket.assigns.return_to)}

      {:error, %Ecto.Changeset{} = changeset} ->
        IO.inspect(changeset, label: "changeset---the server wasn't happy about the question")
        {:noreply, assign(socket, :changeset, changeset)}
    end
  end
end
