defmodule Newton.ProblemTest do
  use Newton.DataCase, async: true

  alias Newton.Problem
  alias Newton.QuestionPage
  alias Newton.Factory
  alias Newton.Problem.Question

  describe "paged_questions/1" do
    setup do
      # Insert 100 test questions
      for _ <- 1..100 do
        Factory.insert(:question)
      end

      :ok
    end

    test "smoke" do
      assert length(Problem.list_questions()) == 100
    end

    test "first page" do
      assert %{results: r, next_page: %QuestionPage{page: 1, page_length: 10}, previous_page: nil} =
               Problem.paged_questions(QuestionPage.new("", page_length: 10))

      assert length(r) == 10
    end

    test "last page" do
      assert %{results: r, next_page: nil, previous_page: %QuestionPage{page: 8, page_length: 11}} =
               Problem.paged_questions(QuestionPage.new("", page: 9, page_length: 11))

      assert length(r) == 1
    end
  end

  describe "paged_questions/1 with filtering" do
    setup do
      # Insert 100 test questions
      for i <- 1..100 do
        tags =
          Enum.filter(2..51, &(rem(i, &1) == 0))
          |> Enum.map(&"tag#{&1}")

        text =
          Enum.filter(2..51, &(rem(i, &1) == 0))
          |> Enum.map(&Factory.gimme_a_word/1)
          |> Enum.join(" ")

        Factory.insert(:question, tags: tags, text: text)
      end

      :ok
    end

    test "finds with one tag" do
      assert %{results: r, next_page: nil, previous_page: nil} =
               Problem.paged_questions(QuestionPage.new("[tag2]", page_length: 100))

      assert length(r) == 50

      assert %{results: r, next_page: nil, previous_page: nil} =
               Problem.paged_questions(QuestionPage.new("[tag3]", page_length: 100))

      assert length(r) == 33
    end

    test "finds with several tags" do
      assert %{results: r, next_page: nil, previous_page: nil} =
               Problem.paged_questions(QuestionPage.new("[tag3] [tag2]", page_length: 100))

      assert length(r) == 16
    end

    test "returns empty list with no matches" do
      assert %{results: [], next_page: nil, previous_page: nil} =
               Problem.paged_questions(QuestionPage.new("[tag101]", page_length: 100))
    end

    test "finds one with a unique tag" do
      assert %{results: [%Question{tags: ["tag3", "tag17", "tag51"]}], next_page: nil, previous_page: nil} =
               Problem.paged_questions(QuestionPage.new("[tag51]", page_length: 100))
    end

    test "paginates properly when some tags are in play" do
      assert %{results: r1, next_page: np, previous_page: nil} =
               Problem.paged_questions(QuestionPage.new("[tag3]", page_length: 25))

      assert length(r1) == 25

      assert %{results: r2, next_page: nil, previous_page: pp} = Problem.paged_questions(np)

      assert length(r2) == 8

      assert %{results: ^r1, next_page: ^np, previous_page: nil} = Problem.paged_questions(pp)
    end

    test "finds with one word fragment" do
      # matches "carbon"
      assert %{results: r, next_page: nil, previous_page: nil} =
               Problem.paged_questions(QuestionPage.new("arb", page_legnth: 50))

      assert length(r) == 16
    end

    test "finds with one word fragment and some tags (match narrows)" do
      # matches "carbon"
      assert %{results: r, next_page: nil, previous_page: nil} =
               Problem.paged_questions(QuestionPage.new("arb [tag12] [tag2]", page_legnth: 50))

      assert length(r) == 8
    end

    test "no matches when text is not present" do
      assert %{results: [], next_page: nil, previous_page: nil} =
               Problem.paged_questions(QuestionPage.new("this_is_not_an_element [tag2]"))
    end
  end

  describe "escape_like_query/1" do
    test "no special chars" do
      assert "foo bar baz" == Problem.escape_like_query("foo bar baz")
    end

    test "backslashes" do
      assert "\\\\int \\\\emph" == Problem.escape_like_query("\\int \\emph")
    end

    test "other regex characters" do
      assert "\\(parens\\) \\\\thingy\\_thingy \\[brackets\\] \\{braces\\} \\?huh \\|\\| \\* \\+" ==
               Problem.escape_like_query("(parens) \\thingy_thingy [brackets] {braces} ?huh || * +")
    end
  end

  describe "questions" do
    alias Newton.Problem.Question

    @valid_attrs %{
      archived: true,
      last_edit_hash: "some last_edit_hash",
      tags: [],
      text: "some text",
      type: "free_response",
      name: "a name"
    }
    @update_attrs %{
      archived: false,
      last_edit_hash: "some updated last_edit_hash",
      tags: [],
      text: "some updated text",
      type: "multiple_choice",
      name: "a different name"
    }
    @invalid_attrs %{archived: nil, last_edit_hash: nil, tags: nil, text: nil, type: nil}

    def question_fixture(attrs \\ %{}) do
      {:ok, question} =
        attrs
        |> Enum.into(@valid_attrs)
        |> Problem.create_question()

      question
    end

    test "list_questions/0 returns all questions" do
      question = question_fixture()
      assert Problem.list_questions() == [question]
    end

    test "get_question!/1 returns the question with given id" do
      question = question_fixture()
      assert Problem.get_question!(question.id) == question
    end

    test "create_question/1 with valid data creates a question" do
      assert {:ok, %Question{} = question} = Problem.create_question(@valid_attrs)
      assert question.archived == true
      assert question.last_edit_hash == "some last_edit_hash"
      assert question.tags == []
      assert question.text == "some text"
      assert question.type == "free_response"
      assert question.name == "a name"
    end

    test "create_question/1 with long text is OK" do
      assert {:ok, %Question{} = question} =
               Problem.create_question(%{
                 name: "test question",
                 type: "multiple_choice",
                 text: """
                 Hello world:
                 \begin{tikzpicture}
                 \draw[help lines] (-1, -1) grid (5, 5);
                 \end{tikzpicture}
                 This is a sample of some long text. Previously this would make the db
                 have a small fit, but hopefully we've got that sorted by now!
                 """
               })
    end

    test "create_question/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Problem.create_question(@invalid_attrs)
    end

    test "update_question/2 with valid data updates the question" do
      question = question_fixture()
      assert {:ok, %Question{} = question} = Problem.update_question(question, @update_attrs)
      assert question.archived == false
      assert question.last_edit_hash == "some updated last_edit_hash"
      assert question.tags == []
      assert question.text == "some updated text"
      assert question.type == "multiple_choice"
      assert question.name == "a different name"
    end

    test "update_question/2 with invalid data returns error changeset" do
      question = question_fixture()
      assert {:error, %Ecto.Changeset{}} = Problem.update_question(question, @invalid_attrs)
      assert question == Problem.get_question!(question.id)
    end

    test "delete_question/1 deletes the question" do
      question = question_fixture()
      assert {:ok, %Question{}} = Problem.delete_question(question)
      assert_raise Ecto.NoResultsError, fn -> Problem.get_question!(question.id) end
    end

    test "change_question/1 returns a question changeset" do
      question = question_fixture()
      assert %Ecto.Changeset{} = Problem.change_question(question)
    end
  end

  describe "answers" do
    alias Newton.Problem.Answer

    @valid_attrs %{display: true, points_marked: 42, points_unmarked: 42, text: "some text"}
    @update_attrs %{
      display: false,
      points_marked: 43,
      points_unmarked: 43,
      text: "some updated text"
    }
    @invalid_attrs %{display: nil, points_marked: nil, points_unmarked: nil, text: nil}

    def answer_fixture(attrs \\ %{}) do
      {:ok, answer} =
        attrs
        |> Enum.into(@valid_attrs)
        |> Problem.create_answer()

      answer
    end

    test "list_answers/0 returns all answers" do
      answer = answer_fixture()
      assert Problem.list_answers() == [answer]
    end

    test "get_answer!/1 returns the answer with given id" do
      answer = answer_fixture()
      assert Problem.get_answer!(answer.id) == answer
    end

    test "create_answer/1 with valid data creates a answer" do
      assert {:ok, %Answer{} = answer} = Problem.create_answer(@valid_attrs)
      assert answer.display == true
      assert answer.points_marked == 42
      assert answer.points_unmarked == 42
      assert answer.text == "some text"
    end

    test "create_answer/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Problem.create_answer(@invalid_attrs)
    end

    test "update_answer/2 with valid data updates the answer" do
      answer = answer_fixture()
      assert {:ok, %Answer{} = answer} = Problem.update_answer(answer, @update_attrs)
      assert answer.display == false
      assert answer.points_marked == 43
      assert answer.points_unmarked == 43
      assert answer.text == "some updated text"
    end

    test "update_answer/2 with invalid data returns error changeset" do
      answer = answer_fixture()
      assert {:error, %Ecto.Changeset{}} = Problem.update_answer(answer, @invalid_attrs)
      assert answer == Problem.get_answer!(answer.id)
    end

    test "delete_answer/1 deletes the answer" do
      answer = answer_fixture()
      assert {:ok, %Answer{}} = Problem.delete_answer(answer)
      assert_raise Ecto.NoResultsError, fn -> Problem.get_answer!(answer.id) end
    end

    test "change_answer/1 returns a answer changeset" do
      answer = answer_fixture()
      assert %Ecto.Changeset{} = Problem.change_answer(answer)
    end
  end

  describe "comments" do
    alias Newton.Problem.Comment

    @valid_attrs %{resolved: true, text: "some text"}
    @update_attrs %{resolved: false, text: "some updated text"}
    @invalid_attrs %{resolved: nil, text: nil}

    def comment_fixture(attrs \\ %{}) do
      {:ok, comment} =
        attrs
        |> Enum.into(@valid_attrs)
        |> Problem.create_comment()

      comment
    end

    test "list_comments/0 returns all comments" do
      comment = comment_fixture()
      assert Problem.list_comments() == [comment]
    end

    test "get_comment!/1 returns the comment with given id" do
      comment = comment_fixture()
      assert Problem.get_comment!(comment.id) == comment
    end

    test "create_comment/1 with valid data creates a comment" do
      assert {:ok, %Comment{} = comment} = Problem.create_comment(@valid_attrs)
      assert comment.resolved == true
      assert comment.text == "some text"
    end

    test "create_comment/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Problem.create_comment(@invalid_attrs)
    end

    test "update_comment/2 with valid data updates the comment" do
      comment = comment_fixture()
      assert {:ok, %Comment{} = comment} = Problem.update_comment(comment, @update_attrs)
      assert comment.resolved == false
      assert comment.text == "some updated text"
    end

    test "update_comment/2 with invalid data returns error changeset" do
      comment = comment_fixture()
      assert {:error, %Ecto.Changeset{}} = Problem.update_comment(comment, @invalid_attrs)
      assert comment == Problem.get_comment!(comment.id)
    end

    test "delete_comment/1 deletes the comment" do
      comment = comment_fixture()
      assert {:ok, %Comment{}} = Problem.delete_comment(comment)
      assert_raise Ecto.NoResultsError, fn -> Problem.get_comment!(comment.id) end
    end

    test "change_comment/1 returns a comment changeset" do
      comment = comment_fixture()
      assert %Ecto.Changeset{} = Problem.change_comment(comment)
    end
  end

  describe "tags" do
    alias Newton.Problem.Tag

    @valid_attrs %{color: "some color", name: "some name"}
    @update_attrs %{color: "some updated color", name: "some updated name"}
    @invalid_attrs %{color: nil, name: nil}

    def tag_fixture(attrs \\ %{}) do
      {:ok, tag} =
        attrs
        |> Enum.into(@valid_attrs)
        |> Problem.create_tag()

      tag
    end

    test "list_tags/0 returns all tags" do
      tag = tag_fixture()
      assert Problem.list_tags() == [tag]
    end

    test "get_tag!/1 returns the tag with given id" do
      tag = tag_fixture()
      assert Problem.get_tag!(tag.id) == tag
    end

    test "create_tag/1 with valid data creates a tag" do
      assert {:ok, %Tag{} = tag} = Problem.create_tag(@valid_attrs)
      assert tag.color == "some color"
      assert tag.name == "some name"
    end

    test "create_tag/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Problem.create_tag(@invalid_attrs)
    end

    test "update_tag/2 with valid data updates the tag" do
      tag = tag_fixture()
      assert {:ok, %Tag{} = tag} = Problem.update_tag(tag, @update_attrs)
      assert tag.color == "some updated color"
      assert tag.name == "some updated name"
    end

    test "update_tag/2 with invalid data returns error changeset" do
      tag = tag_fixture()
      assert {:error, %Ecto.Changeset{}} = Problem.update_tag(tag, @invalid_attrs)
      assert tag == Problem.get_tag!(tag.id)
    end

    test "delete_tag/1 deletes the tag" do
      tag = tag_fixture()
      assert {:ok, %Tag{}} = Problem.delete_tag(tag)
      assert_raise Ecto.NoResultsError, fn -> Problem.get_tag!(tag.id) end
    end

    test "change_tag/1 returns a tag changeset" do
      tag = tag_fixture()
      assert %Ecto.Changeset{} = Problem.change_tag(tag)
    end
  end

  describe "question with assocs" do
    alias Newton.Problem
    alias Newton.Problem.{Question, Comment, Answer}

    test "new question with a comment" do
      assert {:ok, %Question{comments: [%Comment{}], answers: [%Answer{}, %Answer{}]} = q} =
               Problem.create_question(%{
                 name: "Some name",
                 text: "Sample body text",
                 type: "multiple_choice",
                 comments: [%{resolved: false, text: "I'm not happy Bob."}],
                 answers: [
                   %{points_marked: 1, text: "good answer"},
                   %{points_marked: 0, text: "bad answer"}
                 ]
               })

      assert {:ok, a1} = Problem.create_answer(%{question_id: q.id, text: "different answer"})

      q2 = Repo.preload(q, :answers, force: true)
      assert Enum.count(q2.answers) == 3
    end
  end

  describe "exams" do
    alias Newton.Problem.Exam

    @valid_attrs %{
      barcode: "some barcode",
      course_code: "some course_code",
      course_name: "some course_name",
      exam_date: "some exam_date",
      name: "some name",
      stamp: "some stamp"
    }
    @update_attrs %{
      barcode: "some updated barcode",
      course_code: "some updated course_code",
      course_name: "some updated course_name",
      exam_date: "some updated exam_date",
      name: "some updated name",
      stamp: "some updated stamp"
    }
    @invalid_attrs %{barcode: nil, course_code: nil, course_name: nil, exam_date: nil, name: nil, stamp: nil}

    def exam_fixture(attrs \\ %{}) do
      {:ok, exam} =
        attrs
        |> Enum.into(@valid_attrs)
        |> Problem.create_exam()

      exam
    end

    test "list_exams/0 returns all exams" do
      exam = exam_fixture()
      assert Problem.list_exams() == [exam]
    end

    test "get_exam!/1 returns the exam with given id" do
      exam = exam_fixture()
      assert Problem.get_exam!(exam.id) == exam
    end

    test "create_exam/1 with valid data creates a exam" do
      assert {:ok, %Exam{} = exam} = Problem.create_exam(@valid_attrs)
      assert exam.barcode == "some barcode"
      assert exam.course_code == "some course_code"
      assert exam.course_name == "some course_name"
      assert exam.exam_date == "some exam_date"
      assert exam.name == "some name"
      assert exam.stamp == "some stamp"
    end

    test "create_exam/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Problem.create_exam(@invalid_attrs)
    end

    test "update_exam/2 with valid data updates the exam" do
      exam = exam_fixture()
      assert {:ok, %Exam{} = exam} = Problem.update_exam(exam, @update_attrs)
      assert exam.barcode == "some updated barcode"
      assert exam.course_code == "some updated course_code"
      assert exam.course_name == "some updated course_name"
      assert exam.exam_date == "some updated exam_date"
      assert exam.name == "some updated name"
      assert exam.stamp == "some updated stamp"
    end

    test "update_exam/2 with invalid data returns error changeset" do
      exam = exam_fixture()
      assert {:error, %Ecto.Changeset{}} = Problem.update_exam(exam, @invalid_attrs)
      assert exam == Problem.get_exam!(exam.id)
    end

    test "delete_exam/1 deletes the exam" do
      exam = exam_fixture()
      assert {:ok, %Exam{}} = Problem.delete_exam(exam)
      assert_raise Ecto.NoResultsError, fn -> Problem.get_exam!(exam.id) end
    end

    test "change_exam/1 returns a exam changeset" do
      exam = exam_fixture()
      assert %Ecto.Changeset{} = Problem.change_exam(exam)
    end
  end
end
