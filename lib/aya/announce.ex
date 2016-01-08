defmodule Aya.Announce do
  import Plug.Conn

  @moduledoc """
  Handles announce requests.
  """

  @doc """
  Top level function which begins handling of the announce requests. It'll return the response if
  a `{:ok, resp}` tuple is returned, and return a bencoded error response otherwise.
  """
  def handle(conn, user \\ nil) do
    case get_response(conn, user) do
      {:ok, resp} -> resp
      {:error, reason} -> Aya.Util.bad_request(conn, reason)
    end
  end

  @doc """
  Does top level validation of all the necessary portions of the announce request,
  then sends it to the proper torrent GenServer. The `with` statement allows errors
  to "bubble up", and effectively allows the request to be handled by a chain of middleware
  which must all return succesful results.
  """
  def get_response(conn, user) do
    conn = fetch_query_params(conn)
    with {:ok, {hash, peer_id, _port, _ul, _dl, left} = params} <- validate_params(conn.params),
         :ok <- validate_peer_id(peer_id),
         :ok <- validate_torrent(hash, user),
         {:ok, num_want} <- get_num_want(conn.params),
         {:ok, event} <- get_event(conn.params, left),
         {:ok, ip} <- validate_ip(conn.params, conn.remote_ip),
         :ok <- validate_event(event, user),
         {:ok, resp} <- Aya.Util.find_and_call(hash, {:announce, params, {num_want, event, ip}, user}),
    do: {:ok, Plug.Conn.send_resp(conn, 200, resp)}
  end

  @doc """
  Validates all the required parameters in the announce request.
  """
  def validate_params(params) do
    with {:ok, hash} <- get_string(params, "info_hash"),
         {:ok, peer} <- get_string(params, "peer_id"),
         {:ok, port} <- get_int(params, "port"),
         {:ok, ul} <- get_int(params, "uploaded"),
         {:ok, dl} <- get_int(params, "downloaded"),
         {:ok, left} <- get_int(params, "left"),
      do: {:ok, {hash, peer, port, ul, dl, left}}
  end

  @doc """
  Convenience function for accessing a map value which is a string.
  On failure it returns the default parameter, which will trigger an
  error in the with match and return a Malformed Request error.
  """
  def get_string(params, key, default \\ {:error, "Malformed request"}) do
    case Map.fetch(params, key) do
      {:ok, val} ->
        if is_binary(val) do
          {:ok, val}
        else
          default
        end
      _ -> default
    end
  end

  @doc """
  Convenience function for accessing a map value which is an integer.
  It functions similarly to get_string/3.
  """
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

  @doc """
  Returns the number of peers that the peer should receive. It reads the environment
  variable :max_returned_peers, and defaults to 50.
  """
  def get_num_want(params) do
    max_peers = Application.get_env(:aya, :max_returned_peers, 50)
    {:ok, amount} = get_int(params, "num_want", {:ok, max_peers})
    if amount > max_peers || amount < 1 do
      {:ok, max_peers}
    else
      {:ok, amount}
    end
  end

  @doc """
  Determines the event to be used. The event is either
  :seeding, :leeching, or :stopped. If no event is explicitly
  given in the request, it will determine the event based on the
  amount of data left.
  """
  def get_event(params, left) do
    check_left = fn left ->
      if left == 0 do
        {:ok, :seeding}
      else
        {:ok, :leeching}
      end
    end

    case get_string(params, "event", "unknown") do
      {:ok, "stopped"} -> {:ok, :stopped}
      {:ok, "completed"} -> {:ok, :seeding}
      {:ok, "started"} -> check_left.(left)
      {:ok, _} -> {:error, "Invalid request"}
      _ -> check_left.(left)
    end
  end

  @doc """
  Checks that a peer id is valid. If the whitelist is not active, any peer id is acceptable.
  Otherwise, only those which have a matching prefix will be allowed.
  """
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

  @doc """
  Uses the driver to check if a torrent's hash is acceptable.
  """
  def validate_torrent(hash, user) do
    driver = :poolboy.checkout(:driver_pool)
    GenServer.call(driver, {:check_torrent, hash, user})
    :poolboy.checkin(:driver_pool, driver)
  end

  @doc """
  Uses the driver to check if an client event is acceptable.
  """
  def validate_event(event, user) do
    driver = :poolboy.checkout(:driver_pool)
    GenServer.call(driver, {:check_event, event, user})
    :poolboy.checkin(:driver_pool, driver)
  end

  @doc """
  Attempts to use a given ip address and convert it to a proper tuple,
  otherwise it will default to the ip given by Plug.
  """
  def validate_ip(params, default_ip) do
    case get_string(params, "ip", nil) do
      nil -> {:ok, default_ip}
      {:ok, ip_str} ->
        ip = :inet_parse.address(ip_str |> String.to_char_list)
        case ip do
          {:ok, _} -> ip
          _ -> {:error, "Invalid IP address"}
        end
    end
  end
end
