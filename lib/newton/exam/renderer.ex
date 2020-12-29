defmodule Newton.Exam.Renderer do
  @moduledoc """
  Compiles and renders exams.
  """

  require EEx
  require Logger

  alias Newton.Repo
  alias Newton.Problem.Exam

  @common_asset_root "lib/newton/exam/common_assets"

  # Exam, README, and Makefile rendering functions
  EEx.function_from_file(
    :defp,
    :layout_makefile,
    Path.join(@common_asset_root, "Makefile.eex"),
    [:latex_engine]
  )

  EEx.function_from_file(
    :defp,
    :layout_readme,
    Path.join(@common_asset_root, "README.txt.eex"),
    [:latex_engine]
  )

  EEx.function_from_file(
    :defp,
    :layout_exam,
    Path.join(@common_asset_root, "exam.tex.eex"),
    [:exam, :mc_questions, :fr_questions, :bl_questions]
  )

  @doc """
  Given an exam, turn it into a PDF and zip it up.

  Returns an `:ok` tuple with the path to the file, or
  `{:error, "error message"}`.
  """
  @spec compile_exam(exam :: Exam.t()) :: {:ok, Path.t()} | {:error, String.t()}
  def compile_exam(%Exam{} = exam) do
    exam = Repo.preload(exam, :questions)

    exam_name =
      exam.name
      |> (fn n -> Regex.replace(~r/[^[:alnum:] ]/, n, "") end).()
      |> (fn n -> Regex.replace(~r/\s/, n, "_") end).()

    base_dir = Application.fetch_env!(:newton, :exam_folder_base)
    zip_file = Path.join(base_dir, "#{exam_name}.zip")

    try do
      exam
      |> ensure_exam_dir!()
      |> populate_assets!()
      |> format_exam!(exam)
      |> run_make!()
      |> zip_dir(zip_file)

      {:ok, zip_file}
    rescue
      e ->
        Logger.error("Error rendering exam: #{inspect(e)}")
        {:error, "Error rendering exam: #{inspect(e)}"}
    end
  end

  @doc """
  Ensures that a directory to hold the contents of the directory
  exists and is empty. Raises if unable to create or clear directory.
  Returns the path to the exam's fresh folder.
  """
  @spec ensure_exam_dir!(Exam.t()) :: Path.t()
  def ensure_exam_dir!(%Exam{id: exam_id} = _exam) do
    # Make sure that we have got a directory:
    base_dir = Application.fetch_env!(:newton, :exam_folder_base)

    unless File.dir?(base_dir) do
      File.mkdir_p!(base_dir)
    end

    # If 
    exam_dir = Path.join(base_dir, exam_id)

    case File.mkdir(exam_dir) do
      # First time rendering
      :ok ->
        exam_dir

      # Exists; clear out the old copy and create a new directory
      {:error, :eexist} ->
        Logger.info("Folder for #{exam_id} exists; removing and creating a fresh one")
        File.rm_rf!(exam_dir)
        File.mkdir!(exam_dir)
        exam_dir

      _ ->
        raise "Unable to create a fresh directory for exam #{exam_id} at #{exam_dir}"
    end
  end

  @doc """
  Add all necessary .sty files, the Makefile, etc. into the exam
  root's directory.

  Returns the exam root.
  """
  @spec populate_assets!(Path.t()) :: Path.t()
  def populate_assets!(exam_root) do
    # Makefile
    makefile_cont = layout_makefile(Application.fetch_env!(:newton, :latex_program))
    File.write!(Path.join(exam_root, "Makefile"), makefile_cont)

    # README.txt
    readme_cont = layout_readme(Application.fetch_env!(:newton, :latex_program))
    File.write!(Path.join(exam_root, "README.txt"), readme_cont)

    # .sty latex headers
    for sty_file <- Path.wildcard(Path.join(@common_asset_root, "*.sty")) do
      File.cp!(
        sty_file,
        Path.join(exam_root, Path.basename(sty_file))
      )
    end

    exam_root
  end

  @doc """
  Format the base exam file by formatting all the questions and
  dumping them into the exam file.

  Returns the exam root directory.
  """
  @spec format_exam!(exam_root :: Path.t(), exam :: Exam.t()) :: Path.t()
  def format_exam!(exam_root, %Exam{} = exam) do
    exam = Repo.preload(exam, :questions)

    mc_questions = Enum.filter(exam.questions, &(&1.type == "multiple_choice"))
    fr_questions = Enum.filter(exam.questions, &(&1.type == "free_response"))
    bl_questions = Enum.filter(exam.questions, &(&1.type == "fill_in_the_blank"))

    exam_content = layout_exam(exam, mc_questions, fr_questions, bl_questions)
    File.write!(Path.join(exam_root, "exam.tex"), exam_content)

    exam_root
  end

  @doc """
  Run make in the given directory
  """
  @spec run_make!(exam_root :: Path.t()) :: Path.t()
  def run_make!(exam_root) do
    case System.cmd("make", [], cd: exam_root, env: [{"LATEX_FLAGS", "-halt-on-error"}, {"LATEX_CLEANUP_AUX", "true"}]) do
      {_output, 0} ->
        Logger.info("Make ran without problems; exam built in #{exam_root}")

        Logger.info("Cleaning up aux latex files...")

        case System.cmd("make", ["clean"], cd: exam_root) do
          {_, 0} ->
            Logger.info("Cleaning up aux latex files... done.")

          {err, err_code} ->
            Logger.warn("Unable to cleanup aux files! (#{err_code})\n#{err}")
        end

        exam_root

      {err, err_code} ->
        Logger.warn("Make command did not succeed; exited with #{err_code}; Output:\n#{err}")
        exam_root
    end
  end

  @doc """
  Zip a directory `exam_root` into `dest`.
  """
  @spec zip_dir(exam_root :: Path.t(), dest :: Path.t()) :: :ok
  def zip_dir(exam_root, dest) do
    # Function to name the entry
    entry_name = &Path.join(Path.basename(dest, ".zip"), Path.relative_to(&1, exam_root))

    exam_root
    |> gather_file_entries
    # Trim off the exam_root from the entry so we don't get a messy
    # zip file
    |> Enum.map(&Zstream.entry(entry_name.(&1), File.stream!(&1)))
    |> Zstream.zip()
    |> Stream.into(File.stream!(dest))
    |> Stream.run()
  end

  @doc """
  List all files under a given folder in a flat list.

  Essentially like running `find dir -type f -print`.
  """
  @spec gather_file_entries(dir :: Path.t()) :: [Path.t()]
  def gather_file_entries(dir) do
    all_files = File.ls!(dir) |> Enum.map(&Path.join(dir, &1))

    Enum.reject(all_files, &File.dir?(&1)) ++
      Enum.flat_map(Enum.filter(all_files, &File.dir?(&1)), &gather_file_entries/1)
  end
end
