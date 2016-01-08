defmodule Aya.Scrape do
  import Plug.Conn

  @moduledoc """
  Handles scrape requests
  """
  def handle(conn, user \\ nil) do
    resp = get_response(conn, user)
    Plug.Conn.send_resp(conn, 200, Bencodex.encode(%{"files" => resp}))
  end

  def get_response(conn, _user) do
    conn = fetch_query_params(conn)
    conn.params
    |> Enum.filter(fn {key, _val} -> key == "info_hash" end)
    |> Enum.map(fn {"info_hash", info_hash} -> {info_hash, get_scrape(info_hash)} end)
    |> Enum.into(%{})
  end

  def get_scrape(info_hash) do
    {:ok, pid} = Aya.Util.get_torrent_proc(info_hash)
    GenServer.call(pid, :scrape)
  end
end
