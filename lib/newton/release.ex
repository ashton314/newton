defmodule Newton.Release do
  @app :newton

  require Logger

  alias Newton.Repo
  alias Newton.Problem
  alias Newton.Exam

  def diagnostics do
    Logger.info("Repos: #{inspect(repos())}")
  end

  def migrate do
    load_app()
    migrate_no_load()
  end

  def migrate_no_load do
    for repo <- repos() do
      {:ok, _, _} = Ecto.Migrator.with_repo(repo, &Ecto.Migrator.run(&1, :up, all: true))
    end
  end

  def rollback(repo, version) do
    load_app()
    {:ok, _, _} = Ecto.Migrator.with_repo(repo, &Ecto.Migrator.run(&1, :down, to: version))
  end

  defp repos do
    Application.fetch_env!(@app, :ecto_repos)
  end

  defp load_app do
    Application.load(@app)
  end

  @doc """
  Dump the set of questions in JSON format

  `opts` gets passed to `Jason.encode/2`; defaults to `maps: :strict, pretty: :false`.
  """
  @spec db_dump(opts :: Keyword.t()) :: {:ok, String.t()} | {:error, Jason.EncodeError.t() | Exception.t()}
  def db_dump(opts \\ []) do
    questions =
      Problem.list_questions()
      |> Enum.map(&Repo.preload(&1, [:comments, :answers]))
      |> Enum.map(&Map.from_struct/1)
      |> Enum.map(&Map.drop(&1, [:__meta__]))

    exams =
      Exam.list_exams()
      |> Enum.map(fn e ->
        e = Repo.preload(e, [:questions])
        # strip just the IDs, since this is a many-to-many relationship
        %{e | questions: Enum.map(e.questions, & &1.id)}
      end)
      |> Enum.map(&Map.from_struct/1)
      |> Enum.map(&Map.drop(&1, [:__meta__]))

    opts = Keyword.merge([maps: :strict, pretty: false], opts)

    Jason.encode(%{questions: questions, exams: exams}, opts)
  end
end
