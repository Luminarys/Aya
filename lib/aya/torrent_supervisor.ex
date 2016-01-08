defmodule Aya.TorrentSupervisor do
  use Supervisor
  import Supervisor.Spec

  @moduledoc """
  The torrent supervisor. It uses a simple_one_for_one format,
  with transient restarts.
  """

  def start_link(opts \\ []) do
    Supervisor.start_link(__MODULE__, :ok, opts)
  end

  def init(:ok) do
    require Logger
    Logger.log :debug, "Starting Torrent Supervisor"
    children = [
      worker(Aya.Torrent, [], restart: :transient)
    ]
    supervise(children, strategy: :simple_one_for_one)
  end
end
