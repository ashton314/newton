defmodule NewtonWeb.QuestionLive.QuestionCard do
  use NewtonWeb, :live_component

  def render(assigns) do
    ~L"""
    <div class="card question-card">
        <div class="card-body">
            <h3 class="card-title"><%= @question.name %></h3>
            <%= @question.text %>
        </div>
    </div>
    """
  end
end
