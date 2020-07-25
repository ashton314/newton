defmodule NewtonWeb.QuestionLive.QuestionFilterList do
  use NewtonWeb, :live_component

  alias NewtonWeb.QuestionLive.QuestionCard

  @impl true
  def update(
        %{id: _id, parent: _parent, exam_id: exam_id, questions: _questions, selected: _selected, filter: _filter} =
          assigns,
        socket
      ) do
    Routes.exam_show_path(socket, :show, exam_id) |> IO.inspect(label: "test id")

    {:ok, assign(socket, assigns)}
  end
end
