defmodule Newton.Exam.Renderer do
  @moduledoc """
  Compiles and renders exams.
  """

  require EEx
  require Logger

  alias Newton.Repo
  alias Newton.Problem.Exam

  # Exam and Makefile rendering functions
  EEx.function_from_file(
    :defp,
    :layout_makefile,
    "lib/newton/exam/common_assets/Makefile.eex",
    [:latex_engine]
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
    IO.inspect(exam, label: "exam")

    exam_root
  end
end
