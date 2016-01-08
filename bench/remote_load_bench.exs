defmodule RemoteLoadBench do
  use Benchfella

  @clients 1..50000
  @torrents 1..10
  @left 0..0

  setup_all do
    Application.ensure_all_started(:httpoison)
  end

  bench "load" do
    hash = Enum.random(@torrents)
    id = Enum.random(@clients)
    left = Enum.random(@left)
    method = Enum.random(["announce", "scrape"])
    [_bench,_file,tracker] = System.argv
    make_request(tracker, hash, id, 1000, method, 0, 0, left)
  end

  def make_request(tracker, hash, id, port, method, ul, dl, left) do
    params = [
      "info_hash=#{hash}",
      "peer_id=#{id}",
      "port=#{port}",
      "uploaded=#{ul}",
      "downloaded=#{dl}",
      "left=#{left}",
    ]
    HTTPoison.get!("#{tracker}/#{method}?#{params |> Enum.join("&")}")
    :ok
  end
end
