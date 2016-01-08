defmodule LoadBench do
  use Benchfella

  @clients 1..50000
  @torrents 1..10
  @left 0..0
  @tracker "http://localhost:4000"

  setup_all do
    Application.ensure_all_started(:httpoison)
    Application.ensure_all_started(:aya)
  end

  bench "load" do
    hash = Enum.random(@torrents)
    id = Enum.random(@clients)
    left = Enum.random(@left)
    method = Enum.random(["announce", "scrape"])
    make_request(hash, id, 1000, method, 0, 0, left)
  end

  def make_request(hash, id, port, method, ul, dl, left) do
    params = [
      "info_hash=#{hash}",
      "peer_id=#{id}",
      "port=#{port}",
      "uploaded=#{ul}",
      "downloaded=#{dl}",
      "left=#{left}",
    ]
    HTTPoison.get!("#{@tracker}/#{method}?#{params |> Enum.join("&")}")
    :ok
  end
end
