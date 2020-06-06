defmodule NewtonWeb.QuestionLive.Index do
  use NewtonWeb, :live_view

  import NewtonWeb.IconHelpers

  alias Newton.Problem
  alias NewtonWeb.QuestionLive.QuestionCard

  @impl true
  def mount(_params, _session, socket) do
    questions = fetch_questions()

    socket =
      socket
      |> assign(:questions, questions)
      |> assign(:image_renders, %{})

    Enum.map(questions, &request_image_render/1)

    {:ok, socket}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :edit, %{"id" => id}) do
    socket
    |> assign(:preview_state, nil)
    |> assign(:preview_contents, nil)
    |> assign(:page_title, "Edit Question")
    |> assign(:question, Problem.get_question!(id))
  end

  defp apply_action(socket, :new, _params) do
    {:ok, question} =
      Problem.create_question(%{
        text: "(Text of the question appears here.)",
        name: "New question",
        type: "multiple_choice"
      })

    socket
    |> assign(:preview_state, nil)
    |> assign(:preview_contents, nil)
    |> assign(:page_title, "New Question")
    |> assign(:question, question)
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "Question Listing")
    |> assign(:question, nil)
  end

  # Handle edits
  @impl true
  def handle_info({:preview_ready, :ok, token}, socket) do
    IO.inspect(token, label: "[handle_info {:preview_ready}] token")

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

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    question = Problem.get_question!(id)
    {:ok, _} = Problem.delete_question(question)

    socket =
      socket
      |> assign(:questions, fetch_questions())
      |> put_flash(:info, "Question deleted")
      |> push_patch(to: "/questions")

    {:noreply, assign(socket, :questions, fetch_questions())}
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

  defp fetch_questions do
    Problem.list_questions()
  end
end
