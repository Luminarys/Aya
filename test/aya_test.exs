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
      "failure reason" => "Invalid URL"
    })
  end

  test "param getting" do
    import Aya.Announce

    params = %{"t" => "passed", "t1" => "0", "t2" => "a0"}
    assert {:ok, "passed"} == get_string(params, "t")
    assert {:error, "Malformed request"} == get_string(params, "unknown")

    assert {:ok, 0} == get_int(params, "t1")
    assert {:error, "Malformed request"} == get_int(params, "t2")
    assert {:error, "Malformed request"} == get_int(params, "unknown")
  end

  test "num want" do
    import Aya.Announce
    negative = %{"num_want" => "-25"}
    under = %{"num_want" => "25"}
    over = %{"num_want" => "75"}

    Application.put_env(:aya, :max_returned_peers, 50)
    assert {:ok, 50} == get_num_want(negative)
    assert {:ok, 25} == get_num_want(under)
    assert {:ok, 50} == get_num_want(over)

    Application.put_env(:aya, :max_returned_peers, 80)
    assert {:ok, 75} == get_num_want(over)
  end

  test "event" do
    import Aya.Announce
    completed = %{"event" => "completed"}
    started = %{"event" => "started"}
    stopped = %{"event" => "stopped"}
    no_event = %{}
    invalid_event = %{"event" => "-25"}

    assert {:ok, :seeding} == get_event(completed, 0)
    assert {:ok, :leeching} == get_event(started, 10)
    assert {:ok, :stopped} == get_event(stopped, 10)

    assert {:error, "Invalid request"} == get_event(invalid_event, 0)
    assert {:error, "Invalid request"} == get_event(invalid_event, 10)

    assert {:ok, :seeding} == get_event(no_event, 0)
    assert {:ok, :leeching} == get_event(no_event, 10)
  end

  test "valid peer id" do
    import Aya.Announce
    valid = "TEST"
    valid2 = "TEETH"
    valid3 = "WARN"
    invalid = "INVALID"

    Application.put_env(:aya, :use_whitelist, false)
    assert :ok == validate_peer_id(valid)
    assert :ok == validate_peer_id(invalid)

    Application.put_env(:aya, :use_whitelist, true)
    Application.put_env(:aya, :whitelist, ["TE", "WA"])
    assert :ok == validate_peer_id(valid)
    assert :ok == validate_peer_id(valid2)
    assert :ok == validate_peer_id(valid3)
    assert {:error, "Your client is not approved"} == validate_peer_id(invalid)
  end

  test "ip parse" do
    import Aya.Announce

    ipv4 = {127,0,0,1}
    ipv6 = {0, 0, 0, 0, 0, 0, 0, 1}
    valid_ipv4 = %{"ip" => "127.0.0.1"}
    valid_ipv6 = %{"ip" => "::1"}

    invalid_ip = %{"ip" => "blah blah"}
    no_ip = %{}
    assert {:ok, ipv4} == validate_ip(valid_ipv4, ipv4)
    assert {:ok, ipv6} == validate_ip(valid_ipv6, ipv6)

    assert {:ok, ipv4} == validate_ip(no_ip, ipv4)
    assert {:ok, ipv6} == validate_ip(no_ip, ipv6)

    assert {:error, "Invalid IP address"} == validate_ip(invalid_ip, ipv4)
  end
end
