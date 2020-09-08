defmodule Newton.Factory do
  use ExMachina.Ecto, repo: Newton.Repo

  alias Newton.Problem.Question

  def question_factory do
    %Question{
      text: "Some fake question",
      tags: [],
      name: Faker.StarWars.character()
    }
  end
end
