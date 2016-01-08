defmodule AyaTest do
  use ExUnit.Case
  use Plug.Test
  doctest Aya

  @opts Aya.Router.init([])

  test "the truth" do
    assert 1 + 1 == 2
  end

  test "Undefined URL" do
    conn = conn(:get, "/unknown")

    conn = Aya.Router.call(conn, @opts)

    assert conn.state == :sent
    assert conn.status == 404
    assert conn.resp_body == Bencodex.encode(%{
      "failure reason" => "Invalid URL path"
    })
  end

end
