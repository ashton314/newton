defmodule Newton.ProblemTest do
  use Newton.DataCase

  alias Newton.Problem

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
end
