defmodule Newton.Release do
  @app :newton

  require Logger

  alias Newton.Repo
  alias Newton.Problem
  alias Newton.Exam

  def diagnostics do
    load_app()
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

  defp start_app do
    load_app()
    Application.put_env(@app, :minimal, true)
    Application.ensure_all_started(@app)
  end

  @doc """
  The **Big Red Button.** Delete every question and exam.

  Must call with `"yes I want to delete every question and exam in the database"` as argument to work.
  """
  def force_drop_everything("yes I want to delete every question and exam in the database") do
    start_app()

    for q <- Problem.list_questions() do
      Problem.delete_question(q)
    end

    for e <- Exam.list_exams() do
      Exam.delete_exam(e)
    end

    :ok
  end

  def import_backup(filename) do
    start_app()

    json =
      filename
      |> File.read!()
      |> Jason.decode!()

    # Handle questions
    for q <- json["questions"] do
      cs = Problem.Question.restore_changeset(q)

      if cs.valid? do
        Repo.insert(cs)
      else
        IO.puts("Error with question #{inspect(q)}: #{inspect(cs)}")
        Process.sleep(1000)
      end
    end

    # Handle exams
    for e <- json["exams"] do
      cs = Problem.Exam.restore_changeset(e)

      if cs.valid? do
        {:ok, exam} = Repo.insert(cs)

        # Hydrate question mapping
        try do
          questions = Enum.map(e["questions"], &Problem.get_question!/1)
          Exam.update_exam_questions(exam, questions)
        catch
          Ecto.NoResultsError = err ->
            IO.puts("Error with exam #{e}: missing question: #{err}")
        end
      else
        IO.puts("Error with exam #{e}: #{inspect(cs)}")
      end
    end
  end

  def force_preview_rerender() do
    start_app()

    base_dir = Application.fetch_env!(:newton, :latex_cache)
    files = File.ls!(base_dir)

    IO.puts("This operation will remove #{length(files)} files from #{base_dir}; proceed? [yes/No] ")

    if String.trim(IO.read(:line)) == "yes" do
      IO.puts("Flushing image preview...")
      hard_force_preview_rerender()
    else
      IO.puts("Aborted")
    end
  end

  def hard_force_preview_rerender() do
    start_app()

    base_dir = Application.fetch_env!(:newton, :latex_cache)
    files = File.ls!(base_dir)

    # Clear out the entire cache
    for f <- files do
      IO.puts("Removed cache for #{f}")

      File.rm_rf(Path.join(base_dir, f))
    end

    # Rerender all images
    for q <- Problem.list_questions() do
      IO.puts("\n\nRequesting render for #{q.id}...")

      me = self()

      Problem.Render.render_image_preview(
        q,
        fn
          {:ok, _tok} -> send(me, :proceed)
          {:error, mess} -> send(me, {:error, mess})
        end
      )

      # This forces us to go one at a time
      receive do
        :proceed ->
          IO.puts("\nSuccessfully rendered #{q.id}")

        {:error, e} ->
          IO.puts("\nError for #{q.id}: #{inspect(e)}")
      end
    end
  end

  @doc """
  Dump data pretty-formatted
  """
  def db_dump_pretty() do
    start_app()

    case db_dump(pretty: true) do
      {:ok, json} -> IO.puts(json)
      {:error, e} -> IO.puts("Error: #{inspect(e)}")
    end
  end

  @doc """
  Dump the set of questions in JSON format

  `opts` gets passed to `Jason.encode/2`; defaults to `maps: :strict, pretty: :false`.
  """
  @spec db_dump(opts :: Keyword.t()) :: {:ok, String.t()} | {:error, Jason.EncodeError.t() | Exception.t()}
  def db_dump(opts \\ []) do
    start_app()

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
