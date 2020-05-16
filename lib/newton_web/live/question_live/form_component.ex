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
     |> assign(:answer_changeset, answer_changeset())
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

    if is_nil(prev_state) && question.text != "", do: request_render(question)

    {:ok,
     socket
     |> assign(assigns)
     |> assign_new(:changeset, fn -> Problem.change_question(question) end)
     |> assign_new(:answer_changeset, fn -> answer_changeset() end)
     |> assign_new(:comments, fn -> question.comments end)
     |> assign_new(:answers, fn -> question.answers end)
     |> assign_new(:preview_contents, fn -> prev_cont end)
     |> assign_new(:preview_state, fn -> prev_state end)}
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

  def handle_event("validate-answer", %{"new_answer" => new_answer}, socket) do
    {:noreply, assign(socket, :answer_changeset, answer_changeset(new_answer))}
  end

  def handle_event("append-answer", %{"new_answer" => new_answer}, socket) do
    answer_cs = Problem.Answer.changeset(%Problem.Answer{}, new_answer)

    if answer_cs.valid? do
      new_answer = Ecto.Changeset.apply_changes(answer_cs)

      socket =
        socket
        |> update(:answers, fn answers -> answers ++ [new_answer] end)
        |> assign(:answer_changeset, answer_changeset())

      {:noreply, socket}
    else
      error_changeset =
        Ecto.Changeset.add_error(socket.assigns.answer_changeset, :text, "Can't be blank")

      {:noreply, assign(socket, :answer_changeset, error_changeset)}
    end
  end

  def handle_event("save", %{"question" => question_params}, socket) do
    save_question(socket, socket.assigns.action, question_params)
  end

  def handle_event("mark-correct", val, socket) do
    IO.inspect(val, label: "val")

    {:noreply, socket}
  end

  defp answer_changeset(props \\ %{}) do
    types = %{text: :string, is_correct: :boolean}

    {%{}, types}
    |> Ecto.Changeset.cast(props, Map.keys(types))
    |> Ecto.Changeset.validate_required([:text])
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
