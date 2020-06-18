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
    schedule_work()
    {:noreply, state}
  end

  defp schedule_work() do
    # Run every minute
    Process.send_after(self(), :gc, 60 * 1000)
  end
end
