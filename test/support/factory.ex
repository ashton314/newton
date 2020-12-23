defmodule Newton.Factory do
  use ExMachina.Ecto, repo: Newton.Repo

  alias Newton.Problem.Question
  alias Newton.Problem.Exam
  alias Newton.Problem.Answer

  def question_factory do
    %Question{
      text: Faker.StarWars.quote(),
      tags: [],
      type: "multiple_choice",
      answers: [build(:answer, points_marked: 1), build(:answer), build(:answer)],
      name: Faker.StarWars.character()
    }
  end

  def answer_factory do
    %Answer{
      points_marked: 0,
      text: Faker.Lorem.sentence()
    }
  end

  def exam_factory do
    %Exam{
      name: sequence("name"),
      course_code: sequence("coursecode"),
      course_name: sequence("coursename"),
      exam_date: sequence("examdate"),
      stamp: sequence("stamp"),
      barcode: "10000001",
      questions: [
        build(:question),
        build(:question),
        build(:question),
        build(:question, type: "free_response", answers: []),
        build(:question, type: "free_response", answers: []),
        build(:question, type: "free_response", answers: [])
      ]
    }
  end

  @doc """
  Maps 1..100 -> word
  """
  def gimme_a_word(idx) when is_integer(idx) and idx > 0 and idx < 100 do
    ~w(dark_matter hydrogen helium lithium beryllium boron carbon nitrogen oxygen fluorine neon sodium magnesium aluminum silicon phosphorus sulfur chlorine argon potassium calcium scandium titanium vanadium chromium manganese iron cobalt nickel copper zinc gallium germanium arsenic selenium bromine krypton rubidium strontium yttrium zirconium niobium molybdenum technetium ruthenium rhodium palladium silver cadmium indium tin antimony tellurium iodine xenon cesium barium lanthanum cerium praseodymium neodymium promethium samarium europium gadolinium terbium dysprosium holmium erbium thulium ytterbium lutetium hafnium tantalum tungsten rhenium osmium iridium platinum gold mercury thallium lead bismuth polonium astatine radon francium radium actinium thorium protactinium uranium neptunium plutonium americium curium berkelium californium einsteinium fermium)
    |> Enum.at(idx)
  end
end
