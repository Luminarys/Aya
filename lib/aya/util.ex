defmodule Aya.Util do
  def get_ipv4({a, b, c, d}, port) do
    <<a, b, c, d, port::16>>
  end

  def get_ipv4({_, _, _, _, _, _, _, _}, _port), do: nil

  def get_ipv6({a, b, c, d}, port) do
    <<0::16, 0::16, 0::16, 0::16, 0::16, 65535::16, a::8, b::8, c::8, d::8, port::16>>
  end

  def get_ipv6({a, b, c, d, e, f, g, h} , port) do
    <<a::16, b::16, c::16, d::16, e::16, f::16, g::16, h::16, port::16>>
  end

  def get_torrent_proc(hash) do
    name = "torrent_#{hash |> Base.encode16}" |> String.to_atom
    case Process.whereis(name) do
      nil ->
        {:ok, pid} = Supervisor.start_child(Aya.TorrentSupervisor, [hash, []])
      pid -> {:ok, pid}
    end
  end

  def bad_request(conn, reason, status \\ 200) do
    Plug.Conn.send_resp(conn, status, Bencodex.encode(%{
      "failure reason" => reason
    }))
  end

  def start_trace(time \\ 30) do
    spawn(fn ->
      require Logger
      Logger.log :debug, "Beginning eflame test!"
      :eflame2.write_trace(:global_and_local_calls, '/tmp/ef.test.0', :all, time*1000)
      :eflame2.format_trace('/tmp/ef.test.0', '/tmp/ef.test.0.out')
      Logger.log :debug, "eflame test complete!"
    end)
  end
end
