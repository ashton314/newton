defmodule Newton.Exam.RendererTest do
  use Newton.DataCase, async: true

  alias Newton.Factory

  test "ensure_exam_dir/1" do
    exam = Factory.insert(:exam)

    # Check that there's no folder in our cache yet
    base_dir = Application.fetch_env!(:newton, :exam_folder_base)
    exam_dir = Path.join(base_dir, exam.id)
    refute File.exists?(exam_dir)

    # Now try creating it
    assert exam_dir == Newton.Exam.Renderer.ensure_exam_dir!(exam)
    assert File.exists?(exam_dir)

    # Stuff something in it
    File.touch(Path.join(exam_dir, "foo.txt"))
    assert File.exists?(Path.join(exam_dir, "foo.txt"))

    # Recreate and ensure it's empty
    Newton.Exam.Renderer.ensure_exam_dir!(exam)
    refute File.exists?(Path.join(exam_dir, "foo.txt"))

    # Cleanup
    File.rm_rf!(exam_dir)
  end
end
