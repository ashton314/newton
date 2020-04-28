defmodule NewtonWeb.QuestionLive.QuestionCard do
  use NewtonWeb, :live_component

  def render(assigns) do
    ~L"""
    <div class="card question-card">
        <h3><%= @question.name %></h3>
    </div>
    """
  end
end
