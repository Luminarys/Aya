defmodule BencodeBench do
  use Benchfella

  bench "bencode" do
    map =
    0..10000
    |> Enum.map(fn n -> {n, n} end)
    |> Enum.into(%{})

    enc = Bencodex.encode(map)
    dec = Bencodex.decode(enc)
  end
end
