defmodule NewtonWeb.Router do
  use NewtonWeb, :router
  use Pow.Phoenix.Router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, {NewtonWeb.LayoutView, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/" do
    pipe_through :browser

    pow_routes()
  end

  scope "/", NewtonWeb do
    pipe_through :browser

    live "/", PageLive, :index

    live "/stats", StatsLive

    # Class CRUD
    live "/classes", ClassLive.Index, :index
    live "/classes/new", ClassLive.Index, :new
    live "/classes/:id/edit", ClassLive.Index, :edit
    live "/classes/:id", ClassLive.Show, :show
    live "/classes/:id/show/edit", ClassLive.Show, :edit

    # User CRUD
    live "/users", UserLive.Index, :index
    live "/users/new", UserLive.Index, :new
    live "/users/:id/edit", UserLive.Index, :edit
    live "/users/:id", UserLive.Show, :show
    live "/users/:id/show/edit", UserLive.Show, :edit

    # Question CRUD
    live "/questions", QuestionLive.Index, :index
    live "/questions/new", QuestionLive.Index, :new
    live "/questions/:id/edit", QuestionLive.Index, :edit
    live "/questions/:id", QuestionLive.Show, :show
    live "/questions/:id/show/edit", QuestionLive.Show, :edit

    # Exam CRUD
    live "/exams", ExamLive.Index, :index
    live "/exams/new", ExamLive.Index, :new
    live "/exams/:id/edit", ExamLive.Index, :edit
    live "/exams/:id", ExamLive.Show, :show
    live "/exams/:id/show/edit", ExamLive.Show, :edit

    live "/exams/:id/edit-questions", ExamLive.EditQuestions, :index
    live "/exams/:id/edit-questions/:question_id/edit", ExamLive.EditQuestions, :edit

    # Comment CRUD
    live "/comments", CommentLive.Index, :index
    live "/comments/new", CommentLive.Index, :new
    live "/comments/:id/edit", CommentLive.Index, :edit
    live "/comments/:id", CommentLive.Show, :show
    live "/comments/:id/show/edit", CommentLive.Show, :edit

    # Tag CRUD
    live "/tags", TagLive.Index, :index
    live "/tags/new", TagLive.Index, :new
    live "/tags/:id/edit", TagLive.Index, :edit
    live "/tags/:id", TagLive.Show, :show
    live "/tags/:id/show/edit", TagLive.Show, :edit

    # Answer CRUD
    live "/answers", AnswerLive.Index, :index
    live "/answers/new", AnswerLive.Index, :new
    live "/answers/:id/edit", AnswerLive.Index, :edit
    live "/answers/:id", AnswerLive.Show, :show
    live "/answers/:id/show/edit", AnswerLive.Show, :edit
  end

  # Other scopes may use custom stacks.
  # scope "/api", NewtonWeb do
  #   pipe_through :api
  # end

  # Enables LiveDashboard only for development
  #
  # If you want to use the LiveDashboard in production, you should put
  # it behind authentication and allow only admins to access it.
  # If your application does not have an admins-only section yet,
  # you can use Plug.BasicAuth to set up some basic authentication
  # as long as you are also using SSL (which you should anyway).
  if Mix.env() in [:dev, :test] do
    import Phoenix.LiveDashboard.Router

    scope "/" do
      pipe_through :browser
      live_dashboard "/dashboard", metrics: NewtonWeb.Telemetry
    end
  end
end
