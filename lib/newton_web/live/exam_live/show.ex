defmodule NewtonWeb.ExamLive.Show do
  use NewtonWeb, :live_view

  import NewtonWeb.IconHelpers
  require Logger
  alias Newton.Problem
  alias Newton.Exam
  alias Newton.Exam.Renderer
  alias Newton.QuestionPage
  alias NewtonWeb.QuestionLive

  @default_page_length 25

  @impl true
  def mount(_params, _session, socket) do
    {:ok, assign(socket, image_renders: %{}, download_loading: false)}
  end

  @impl true
  def handle_params(%{"id" => id}, _, socket) do
    exam = Exam.get_exam!(id) |> Newton.Repo.preload([:questions])
    exam_questions = exam.questions
    all_questions = []

    Enum.map(all_questions, &request_image_render/1)

    send(self(), {:search, "", @default_page_length, 0})

    {:noreply,
     socket
     |> assign(:interpretation, %{normal: [], tags: [], refs: []})
     |> assign(:page_title, page_title(socket.assigns.live_action))
     |> assign(:page, 0)
     |> assign(:page_length, @default_page_length)
     |> assign(:next_page, nil)
     |> assign(:previous_page, nil)
     |> assign(:total_count, 0)
     |> assign(:exam, exam)
     |> assign(:exam_questions, exam_questions)
     |> assign(:all_questions, all_questions)
     |> assign(:loading, false)
     |> assign(:download_loading, false)
     |> assign(:download_url, false)
     |> assign(:query, "")}
  end

  defp page_title(:show), do: "Show Exam"
  defp page_title(:edit), do: "Edit Exam"

  @impl true
  def handle_event("toggle_question_inclusion", %{"question-id" => id}, socket) do
    socket =
      if Enum.find(socket.assigns.exam_questions, fn q -> q.id == id end) do
        # It's already on the exam: remove it
        update(socket, :exam_questions, fn qs -> Enum.filter(qs, &(&1.id != id)) end)
      else
        # Add it
        q = Problem.get_question!(id)
        update(socket, :exam_questions, fn qs -> [q | qs] end)
      end

    {:noreply, socket}
  end

  def handle_event("save_questions", _, socket) do
    case Exam.update_exam_questions(socket.assigns.exam, socket.assigns.exam_questions) do
      {:ok, exam} ->
        {:noreply,
         socket
         |> put_flash(:info, "Saved #{length(exam.questions)} questions to exam")
         |> push_redirect(to: Routes.exam_show_path(socket, :show, socket.assigns.exam))}

      {:error, %Ecto.Changeset{} = cs} ->
        Logger.error("Error saving questions: #{inspect(cs)}")

        {:noreply,
         socket
         |> put_flash(:error, "Error: couldn't save questions!")
         |> push_redirect(to: Routes.exam_show_path(socket, :show, socket.assigns.exam))}
    end
  end

  def handle_event("download-exam", _, socket) do
    lv = self()
    exam = socket.assigns.exam

    Task.start(fn ->
      case Renderer.compile_exam(exam) do
        {:ok, path} ->
          send(lv, {:download_ready, path})

        {:error, message} ->
          send(lv, {:download_failed, message})
      end
    end)

    {:noreply, assign(socket, download_loading: true)}
  end

  def handle_event("go-next-page", _, socket) do
    send(self(), {:search, socket.assigns.query, socket.assigns.page_length, socket.assigns.page + 1})
    {:noreply, assign(socket, loading: true, page: socket.assigns.page + 1)}
  end

  def handle_event("go-previous-page", _, socket) do
    send(self(), {:search, socket.assigns.query, socket.assigns.page_length, socket.assigns.page - 1})
    {:noreply, assign(socket, loading: true, page: socket.assigns.page - 1)}
  end

  def handle_event("change_page_length", %{"page_length" => new_length}, socket) do
    parsed_length =
      case Integer.parse(new_length) do
        {int, _} -> int
        _ -> 25
      end

    send(self(), {:search, socket.assigns.query, parsed_length, socket.assigns.page})
    {:noreply, assign(socket, page_length: parsed_length)}
  end

  def handle_event("interpret", %{"q" => query}, socket) do
    {:noreply, assign(socket, interpretation: Newton.QueryParser.parse(query))}
  end

  def handle_event("search", %{"q" => query}, socket) do
    send(self(), {:search, query, socket.assigns.page_length, socket.assigns.page})
    {:noreply, assign(socket, query: query, loading: true)}
  end

  @impl true
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

  def handle_info({:search, query, page_length, page}, socket) do
    %{results: filtered, next_page: np, previous_page: pp, total_count: tc} =
      Problem.paged_questions(QuestionPage.new(query, page: page, page_length: page_length))

    Enum.map(filtered, &request_image_render/1)

    filtered = Enum.map(filtered, &Newton.Repo.preload(&1, [:comments]))

    {:noreply,
     assign(socket, loading: false, all_questions: filtered, next_page: np, previous_page: pp, total_count: tc)}
  end

  def handle_info({:download_ready, path}, socket) do
    base = Application.fetch_env!(:newton, :exam_folder_base)
    path = Path.relative_to(path, base)

    socket =
      socket
      |> assign(download_loading: false)
      |> assign(download_url: Routes.download_path(NewtonWeb.Endpoint, :download, path: path))

    {:noreply, socket}
  end

  def handle_info({:download_failed, err}, socket) do
    IO.inspect(err, label: "got error in download!")

    {:noreply,
     socket
     |> put_flash(:error, "Error: Couldn't render exam for download; check server logs")
     |> push_redirect(to: Routes.exam_show_path(socket, :show, socket.assigns.exam))}
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
