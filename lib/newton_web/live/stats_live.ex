defmodule NewtonWeb.StatsLive do
  use NewtonWeb, :live_view

  alias Newton.Problem
  alias Newton.Problem.Question

  @impl true
  def mount(_params, _session, socket) do
    {:ok, assign(socket, :stats, compute_stats())}
  end

  defp compute_stats do
    questions = Problem.list_questions()
    exams = Problem.list_exams()
    tags = Problem.list_tags_from_questions()

    stats = %{
      totals: %{questions: length(questions), exams: length(exams), tags: length(tags)},
      refs: %{},
      unassigned: []
    }

    # Collate the questions into their sections
    Enum.reduce(questions, stats, fn %Question{} = q, s ->
      {_, new_stats} =
        if is_nil(q.ref_chapter) || q.ref_chapter == "" do
          get_and_update_in(s, [:unassigned], &{&1, [q | &1 || []]})
          # Map.update!(s, :unassigned, &[q | &1])
        else
          get_and_update_in(s, [:refs, q.ref_chapter], fn chapter ->
            new_chapter = chapter || %{unassigned: []}

            {_, new_chapter} =
              if is_nil(q.ref_section) || q.ref_section == "" do
                get_and_update_in(new_chapter, [:unassigned], &{&1, [q | &1 || []]})
              else
                get_and_update_in(new_chapter, [q.ref_section], &{&1, [q | &1 || []]})
              end

            {chapter, new_chapter}
          end)
        end

      new_stats
    end)
  end

  defp flatten_map(struct) do
    Enum.flat_map(struct, fn {key, val} -> val end)
  end
end
