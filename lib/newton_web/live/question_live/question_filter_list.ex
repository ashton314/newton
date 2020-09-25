defmodule NewtonWeb.QuestionLive.QuestionFilterList do
  use NewtonWeb, :live_component

  alias NewtonWeb.QuestionLive.QuestionCard

  @impl true
  def update(
        %{parent: _parent, exam_id: exam_id, questions: _questions, selected: _selected, filter: _filter} = assigns,
        socket
      ) do
    Routes.exam_show_path(socket, :show, exam_id)

    {:ok, assign(socket, assigns)}
  end

  defp maybe_selected_class(question, questions) do
    if Enum.member?(questions, question) do
      "question-selected"
    else
      ""
    end
  end
end
