defmodule Newton.GarbageCollector do
  @moduledoc """
  Task to look for preview renders older than a configurable timeframe and wipe them out.
  """
  use GenServer
  require Logger

  def start_link(_) do
    GenServer.start_link(__MODULE__, %{})
  end

  @impl true
  def init(init_state) do
    Logger.info("[GarbageCollector] Starting up")
    schedule_work()
    {:ok, init_state}
  end

  @impl true
  def handle_info(:gc, state) do
    Logger.info("[GarbageCollector] Waking up")

    max_age =
      Application.get_env(:newton, __MODULE__, max_age: 60)
      |> Keyword.get(:max_age)

    deleted =
      fetch_cache()
      |> older_than(max_age)
      |> Enum.map(&try_delete/1)
      |> Enum.filter(& &1)

    Logger.info("[GarbageCollector] Deleted #{length(deleted)} dirs: #{inspect(deleted)}")

    schedule_work()
    {:noreply, state}
  end

  def try_delete(dir) do
    if File.exists?(dir) do
      Path.wildcard(Path.join(dir, "question_preview*"))
      |> Enum.map(&File.rm!/1)

      case File.rmdir(dir) do
        :ok ->
          dir

        {:error, reason} ->
          Logger.warn("[GarbageCollector] Couldn't delete #{dir}: #{inspect(reason)}")
          false
      end
    else
      :ok
    end
  end

  def older_than(file_list, age) do
    cutoff = System.system_time(:second) - age

    file_list
    |> Enum.map(&{&1, File.stat(&1, time: :posix)})
    |> Enum.filter(fn
      {_, {:ok, %File.Stat{type: :directory}}} ->
        true

      _ ->
        false
    end)
    |> Enum.map(fn {file, {:ok, %File.Stat{ctime: ctime}}} -> {file, ctime} end)
    |> Enum.filter(fn {_, ctime} -> ctime < cutoff end)
    |> Enum.map(fn {file, _} -> file end)
  end

  # Return a list of folders to try deleting in the cache
  def fetch_cache() do
    with {:ok, cache} <- Application.fetch_env(:newton, :latex_cache),
         {:ok, files} <- File.ls(cache) do
      files
      |> Enum.filter(&Regex.match?(~r/^[a-z0-9]+$/, &1))
      |> Enum.map(&Path.join(cache, &1))
    else
      :error ->
        Logger.warn("[GarbageCollector] Could not find cache in config!")
        []

      {:error, posix} ->
        Logger.warn("[GarbageCollector] Could not read files: #{inspect(posix)}")
        []
    end
  end

  defp schedule_work() do
    sleep_for =
      Application.get_env(:newton, __MODULE__, collect_every: 60)
      |> Keyword.get(:collect_every)

    Logger.info("[GarbageCollector] Sleeping for #{sleep_for} seconds")

    Process.send_after(self(), :gc, sleep_for * 1000)
  end
end
