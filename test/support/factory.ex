defmodule Newton.Factory do
  use ExMachina.Ecto, repo: Newton.Repo

  alias Newton.Problem.Question
  alias Newton.Problem.Exam

  def question_factory do
    %Question{
      text: "Some fake question",
      tags: [],
      name: Faker.StarWars.character()
    }
  end

  def exam_factory do
    %Exam{
      name: sequence("name"),
      course_code: sequence("course_code"),
      course_name: sequence("course_name"),
      exam_date: sequence("exam_date"),
      stamp: sequence("stamp"),
      barcode: sequence("barcode"),
      questions: [build(:question), build(:question)]
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
