defmodule Newton.QuestionPage do
  @moduledoc """
  All the state necessary to fetch a page of questions with a
  particular filter.
  """

  alias Newton.QueryParser
  alias __MODULE__

  @default_page_length 25

  defstruct [:query, :page, :page_length]

  @type t :: %QuestionPage{
          query: QueryParser.parsed_query(),
          page: pos_integer(),
          page_length: pos_integer()
        }

  @doc """
  Create a new query.

  Parses the query with `QueryParser.parse/1` before setting it on the
  struct.

  Options:

   - `page`: Page number; integer from zero through positive infinity

   - `page_length`: Number of questions per page; integer from zero
     through positive infinity.
  """
  @spec new(String.t(), Keyword.t()) :: t()
  def new(query, opts \\ [])

  def new(query, opts) do
    %__MODULE__{
      query: QueryParser.parse(query),
      page: Keyword.get(opts, :page, 0),
      page_length: Keyword.get(opts, :page_length, @default_page_length)
    }
  end
end
