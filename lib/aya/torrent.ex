defmodule Aya.Torrent do
  use GenServer

  def start_link(hash, opts \\ []) do
    GenServer.start_link(__MODULE__, {hash}, opts)
  end

  def init({hash}) do
    require Logger
    Logger.log :debug, "Started torrent with hash #{hash |> Base.encode16}!"
    :pg2.join(:torrents, self)
    name = "torrent_#{hash |> Base.encode16}" |> String.to_atom
    Process.register(self, name)
    reap_interval = Application.get_env(:aya, :reap_interval, 60) * 1000
    :erlang.send_after(reap_interval, self, :reap)
    {:ok, {hash, %{}, %{}}}
  end

  def handle_call({:announce, params, extra_params, user}, _who, {_hash, seeders, leechers}) do
    {hash, peer_id, port, ul, dl, left} = params
    {num_want, event, ip} = extra_params

    GenServer.cast(Aya.Driver, {:announce, {hash, ul, dl, left, event}, user})

    {new_seeders, new_leechers} = handle_event(event, seeders, leechers, {peer_id, port, ip})

    peer_resp = case ip do
      {_, _, _, _} -> ipv4_peerlist(num_want, new_seeders, new_leechers)
      {_, _, _, _, _, _, _, _} -> ipv6_peerlist(num_want, new_seeders, new_leechers)
    end

    announce = Application.get_env(:aya, :announce, 1800)
    min_announce = Application.get_env(:aya, :min_announce, 900)

    resp =
    Map.merge(peer_resp, %{
      "interval" => announce,
      "min interval" => min_announce,
      "complete" => Enum.count(new_seeders),
      "incomplete" => Enum.count(new_leechers)
    }) |> Bencodex.encode

    {:reply, {:ok, resp}, {hash, new_seeders, new_leechers}}
  end

  def handle_call(:scrape, _who, {_hash, seeders, leechers} = state) do
    {:reply, %{
        "complete" => Enum.count(seeders),
        "downloaded" => Enum.count(seeders),
        "incomplete" => Enum.count(leechers)
      },
      state}
  end

  def handle_info(:reap, {hash, seeders, leechers}) do
    require Logger
    Logger.log :debug, "Reaping torrent with hash #{hash |> Base.encode16}!"
    announce = Application.get_env(:aya, :announce, 1800)
    reap_interval = Application.get_env(:aya, :reap_multiplier, 1.5) * announce
    now = :os.system_time(:seconds)

    new_seeders =
    seeders
    |> Enum.filter(fn {_id, peer} ->
      now - peer.last_announce < reap_interval
    end)
    |> Enum.into(%{})

    new_leechers =
    leechers
    |> Enum.filter(fn {_id, peer} ->
      now - peer.last_announce < reap_interval
    end)
    |> Enum.into(%{})

    purge_idle = Application.get_env(:aya, :purge_idle_torrents, true)
    if Enum.count(new_seeders) + Enum.count(new_leechers) == 0 && purge_idle do
      GenServer.stop(self)
    else
      reap_interval = Application.get_env(:aya, :reap_interval, 60) * 1000
      :erlang.send_after(reap_interval, self, :reap)
    end

    {:noreply, {hash, new_seeders, new_leechers}}
  end

  def handle_event(event, seeders, leechers, {peer_id, _port, _ip} = params) do
    case event do
      :seeding -> handle_seeding(seeders, leechers, params)
      :leeching -> handle_leeching(seeders, leechers, params)
      :stopped -> handle_stopped(seeders, leechers, peer_id)
    end
  end

  def handle_seeding(seeders, leechers, {peer_id, port, ip}) do
    now = :os.system_time(:seconds)
    case Map.get(leechers, peer_id, nil) do
      nil ->
        case Map.get(seeders, peer_id, nil) do
          nil ->
            peer = %Aya.Peer{
              :last_announce => now,
              :id => peer_id,
              :port => port,
              :ipv4 => Aya.Util.get_ipv4(ip, port),
              :ipv6 => Aya.Util.get_ipv6(ip, port)
            }
            new_seeders = Map.put(seeders, peer_id, peer)
            {new_seeders, leechers}
          peer ->
            new_peer = %{peer | :last_announce => now}
            new_seeders = %{seeders | peer_id => new_peer}
            {new_seeders, leechers}
        end
      _peer ->
        peer_id = Map.get(leechers, peer_id)
        new_seeders = Map.delete(leechers, peer_id)
        new_leechers = Map.put(seeders, peer_id, Aya.Torrent)
        {new_seeders, new_leechers}
    end
  end

  def handle_leeching(seeders, leechers, {peer_id, port, ip}) do
    now = :os.system_time(:seconds)
    case Map.get(leechers, peer_id, nil) do
      nil ->
        peer = %Aya.Peer{
          :last_announce => now,
          :id => peer_id,
          :port => port,
          :ipv4 => Aya.Util.get_ipv4(ip, port),
          :ipv6 => Aya.Util.get_ipv6(ip, port)
        }
        new_leechers = Map.put(leechers, peer_id, peer)
        {seeders, new_leechers}
      peer ->
        new_peer = %{peer | :last_announce => now}
        new_leechers = %{leechers | peer_id => new_peer}
        {seeders, new_leechers}
    end
  end

  def handle_stopped(seeders, leechers, peer_id) do
    new_seeders = Map.delete(seeders, peer_id)
    new_leechers = Map.delete(leechers, peer_id)
    {new_seeders, new_leechers}
  end

  def ipv4_peerlist(num_want, seeders, leechers) do
    pot_seeders = Enum.take_random(seeders, num_want)
    case Enum.count(pot_seeders) do
      50 -> %{"peers" => make_ipv4_peerlist(pot_seeders)}
      amount ->
        %{"peers" => make_ipv4_peerlist(pot_seeders ++ Enum.take_random(leechers, num_want - amount))}
    end
  end

  def make_ipv4_peerlist(peers) do
    peers
    |> Enum.map(fn {_id, peer} -> peer.ipv4 end)
    |> Enum.join
  end

  def ipv6_peerlist(num_want, seeders, leechers) do
    pot_seeders = Enum.take_random(seeders, num_want)
    case Enum.count(pot_seeders) do
      50 ->
        %{"peers6" => make_ipv6_peerlist(pot_seeders), "peers" => ""}
      amount ->
        %{
          "peers6" => make_ipv6_peerlist(pot_seeders ++ Enum.take_random(leechers, num_want - amount)),
          "peers" => ""
        }
    end
  end

  def make_ipv6_peerlist(peers) do
    peers
    |> Enum.map(fn {_id, peer} -> peer.ipv6 end)
    |> Enum.join
  end
end
