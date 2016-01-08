defmodule Aya do
  use Application

  @moduledoc """
  Aya is a fast, lightweight torrent tracker.
  """

  def start(_type, []) do
    start_aya
  end

  def start_aya do
    import Supervisor.Spec, warn: false
    require Logger

    children = [
      supervisor(Aya.TorrentSupervisor, [[name: Aya.TorrentSupervisor]]),
      supervisor(Aya.Driver.Supervisor, [[name: Aya.Driver.Supervisor]])
    ]

    Logger.log :debug, "Starting Aya!"
    :pg2.start()
    {:ok, pid} = Supervisor.start_link(children, strategy: :one_for_one)
    port = Application.get_env(:aya, :port, 4000)
    {:ok, _pid} = Plug.Adapters.Cowboy.http Aya.Router, [], port: port
    {:ok, pid}
  end
end
