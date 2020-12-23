defmodule Newton.Exam.RendererTest do
  use Newton.DataCase, async: true

  alias Newton.Factory
  alias Newton.Exam.Renderer

  describe "basic test rendering" do
    test "ensure_exam_dir/1" do
      exam = Factory.insert(:exam)

      # Check that there's no folder in our cache yet
      base_dir = Application.fetch_env!(:newton, :exam_folder_base)
      exam_dir = Path.join(base_dir, exam.id)
      refute File.exists?(exam_dir)

      # Now try creating it
      assert exam_dir == Renderer.ensure_exam_dir!(exam)
      assert File.exists?(exam_dir)

      # Stuff something in it
      File.touch(Path.join(exam_dir, "foo.txt"))
      assert File.exists?(Path.join(exam_dir, "foo.txt"))

      # Recreate and ensure it's empty
      Renderer.ensure_exam_dir!(exam)
      refute File.exists?(Path.join(exam_dir, "foo.txt"))

      # Cleanup
      File.rm_rf!(exam_dir)
    end

    test "populate_assets!" do
      exam = Factory.insert(:exam)

      # Check that there's no folder in our cache yet
      base_dir = Application.fetch_env!(:newton, :exam_folder_base)
      exam_dir = Path.join(base_dir, exam.id)

      assert exam_dir == Renderer.ensure_exam_dir!(exam)
      assert File.exists?(exam_dir)

      # Ok, now dump the assets
      assert exam_dir == Renderer.populate_assets!(exam_dir)

      # Check that all .sty files are in place
      for sty_file <- ~w(automultiplechoice bophook byuexamheader tabletgrader) do
        assert File.exists?(Path.join(exam_dir, "#{sty_file}.sty"))
      end

      # Check that the Makefile is in place (exam.tex comes later)
      assert File.exists?(Path.join(exam_dir, "Makefile"))
      assert File.exists?(Path.join(exam_dir, "README.txt"))

      latex_program = Application.fetch_env!(:newton, :latex_program)

      # Make sure README got populated correclty
      assert File.read!(Path.join(exam_dir, "README.txt")) =~ "defaults to #{latex_program}"

      # Cleanup
      File.rm_rf!(exam_dir)
    end

    test "exam.tex file exists and has correct contents" do
      exam = Factory.insert(:exam)

      base_dir = Application.fetch_env!(:newton, :exam_folder_base)
      exam_dir = Path.join(base_dir, exam.id)

      # Render!
      exam
      |> Renderer.ensure_exam_dir!()
      |> Renderer.populate_assets!()
      |> Renderer.format_exam!(exam)

      assert File.exists?(exam_dir)
      assert File.exists?(Path.join(exam_dir, "exam.tex"))

      # Ok, check file contents
      exam_cont = File.read!(Path.join(exam_dir, "exam.tex"))

      for q <- exam.questions do
        assert exam_cont =~ q.text
        assert exam_cont =~ q.name
      end

      # Cleanup
      File.rm_rf!(exam_dir)
    end

    test "exam.tex renders ok with known good questions"

    test "failed rendering just produces a zip file with no .pdf inside"
  end

  describe "image assets" do
    @describetag :skip
    test "resources/ folder populated with subfolders for each question in exam"

    test "exam renders with image includes"

    test "exam renders with multiple questions needing included images"

    test "failed rendering handled gracefully: no pdf, but zip file present"
  end
end
