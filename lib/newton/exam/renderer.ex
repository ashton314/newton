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
  Puts all the files for an exam together
  """
  def compile_exam(%Exam{} = exam) do
    exam = Repo.preload(exam, :questions)

    IO.inspect(exam, label: "exam")
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
    case System.cmd("make", [], cd: exam_root, env: [{"LATEX_FLAGS", "-halt-on-error"}]) do
      {_output, 0} ->
        Logger.info("Make ran without problems; exam built in #{exam_root}")
        exam_root

      {err, err_code} ->
        Logger.warn("Make command did not succeed; exited with #{err_code}; Output:\n#{err}")
        exam_root
    end
  end
end
