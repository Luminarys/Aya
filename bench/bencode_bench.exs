defmodule BencodeBench do
  use Benchfella

  bench "bencode" do
    map =
    0..50
    |> Enum.map(fn n -> {n, n} end)
    |> Enum.into(%{})

    enc = Bencodex.encode(map)
  end
end
