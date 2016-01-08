defmodule Aya.Announce do
  import Plug.Conn

  @moduledoc """
  Handles announce requests
  """
  def handle(conn, user \\ nil) do
    case get_response(conn, user) do
      {:ok, resp} -> resp
      {:error, reason} -> Aya.Util.bad_request(conn, reason)
    end
  end

  def get_response(conn, user) do
    conn = fetch_query_params(conn)
    with {:ok, {hash, peer_id, _port, _ul, _dl, left} = params} <- validate_params(conn.params),
         :ok <- validate_peer_id(peer_id),
         :ok <- validate_torrent(hash, user),
         {:ok, num_want} <- get_num_want(conn.params),
         {:ok, event} <- get_event(conn.params, left),
         {:ok, ip} <- validate_ip(conn.params, conn.remote_ip),
         :ok <- validate_event(event, user),
         {:ok, pid} <- Aya.Util.get_torrent_proc(hash),
         {:ok, resp} <- GenServer.call(pid, {:announce, params, {num_want, event, ip}, user}),
    do: {:ok, Plug.Conn.send_resp(conn, 200, resp)}
  end

  def validate_params(params) do
    with {:ok, hash} <- get_string(params, "info_hash"),
         {:ok, peer} <- get_string(params, "peer_id"),
         {:ok, port} <- get_int(params, "port"),
         {:ok, ul} <- get_int(params, "uploaded"),
         {:ok, dl} <- get_int(params, "downloaded"),
         {:ok, left} <- get_int(params, "left"),
      do: {:ok, {hash, peer, port, ul, dl, left}}
  end

  def get_string(params, key, default \\ {:error, "Malformed request"}) do
    case Map.fetch(params, key) do
      {:ok, val} -> {:ok, val}
      _ -> default
    end
  end

  def get_int(params, key, default \\ {:error, "Malformed request"}) do
    try do
      case Map.fetch(params, key) do
        {:ok, val} -> {:ok, String.to_integer(val)}
        _ -> default
      end
    rescue
      ArgumentError -> default
    end
  end

  def get_num_want(params) do
    max_peers = Application.get_env(:aya, :max_returned_peers, 50)
    amount = get_int(params, "num_want", max_peers)
    if amount > max_peers || amount < 1 do
      {:ok, max_peers}
    else
      {:ok, amount}
    end
  end

  def get_event(params, left) do
    event =
    case get_string(params, "event", "unknown") do
      {:ok, "stopped"} -> :stopped
      {:ok, "paused"} -> :stopped
      {:ok, "completed"} -> :seeding
      _ ->
        if left == 0 do
          :seeding
        else
          :leeching
        end
    end
    {:ok, event}
  end

  def validate_peer_id(id) do
    check_id = Application.get_env(:aya, :use_whitelist, false)
    if check_id do
      if String.starts_with?(id, Application.get_env(:aya, :whitelist, [])) do
        :ok
      else
        {:error, "Your client is not approved"}
      end
    else
      :ok
    end
  end

  def validate_torrent(hash, user) do
    GenServer.call(Aya.Driver, {:check_torrent, hash, user})
  end

  def validate_event(event, user) do
    GenServer.call(Aya.Driver, {:check_event, event, user})
  end

  def validate_ip(params, default_ip) do
    case get_string(params, "ip", nil) do
      nil -> {:ok, default_ip}
      {:ok, ip_str} ->
        # Check if ipv6 is allowed by tracker
        ip = :inet_parse.address(ip_str |> String.to_char_list)
        case ip do
          {:ok, _} -> ip
          _ -> {:error, "Invalid IP address"}
        end
    end
  end
end
