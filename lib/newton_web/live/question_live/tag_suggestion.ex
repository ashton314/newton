defmodule NewtonWeb.QuestionLive.TagSuggestion do
  use NewtonWeb, :live_component

  import Ecto.Changeset

  @sample_tags ~w(math112 math113 derivative integral limit easy medium hard)

  @impl true
  def update(assigns, socket) do
    {:ok,
     socket
     |> assign(assigns)
     |> assign_new(:suggestions, fn -> [] end)
     |> assign_new(:changeset, fn -> new_tag_changeset() end)}
  end

  @impl true
  def handle_event("suggest", %{"new_tag" => new_tag}, socket) do
    tag = new_tag["new_tag"]

    matches = Enum.filter(@sample_tags, fn t -> String.contains?(t, tag) end)

    IO.inspect(matches, label: "matches")

    socket =
      socket
      |> update(:changeset, fn cs -> new_tag_changeset(cs, new_tag) end)
      |> assign(:suggestions, matches)

    {:noreply, socket}
  end

  def handle_event("add-tag", %{"new_tag" => %{"new_tag" => new_tag}}, socket) do
    send(self(), {:new_tag, new_tag})
    {:noreply, assign(assign(socket, :suggestions, []), :changeset, new_tag_changeset())}
  end

  defp new_tag_changeset(cs \\ %{}, params \\ %{}) do
    types = %{new_tag: :string}

    {cs, types}
    |> cast(params, [:new_tag])
  end
end
