defmodule NewtonWeb.QuestionLive.QuestionCard do
  use NewtonWeb, :live_component

  def render(assigns) do
    ~L"""
    <div class="card question-card">
      <div class="card-body">
        <div class="row justify-content-between px-3">
          <h3 class="card-title d-inline-block"><%= @question.name %></h3>
            <%= live_patch "Edit", to: Routes.question_index_path(@socket, :edit, @question), class: "btn btn-outline-success" %>
          </div>
          <%= @question.text %>
      </div>
    </div>
    """
  end
end
