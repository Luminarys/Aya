defmodule Aya.Scrape do
  import Plug.Conn

  @moduledoc """
  Handles scrape requests
  """

  @doc """
  Top level function for handling the scrape request.
  """
  def handle(conn, user \\ nil) do
    resp = get_response(conn, user)
    Plug.Conn.send_resp(conn, 200, Bencodex.encode(%{"files" => resp}))
  end

  @doc """
  Runs a map over the client's requested torrents and gets scrape
  info for each, returning a dict which contains all responses.
  """
  def get_response(conn, _user) do
    conn = fetch_query_params(conn)
    conn.params
    |> Enum.filter(fn {key, _val} -> key == "info_hash" end)
    |> Enum.map(fn {"info_hash", info_hash} -> {info_hash, get_scrape(info_hash)} end)
    |> Enum.into(%{})
  end

  @doc """
  Contacts a torrent GenServer and returns its scrape info.
  """
  def get_scrape(info_hash) do
    Aya.Util.find_and_call(info_hash, :scrape)
  end
end
