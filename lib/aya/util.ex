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

  def get_name(bytes), do: "torrent_#{bytes |> Base.encode16}"

  def find_and_call(hash, msg) do
    if Application.get_env(:aya, :distributed, false) do
      call_remote_torrent_proc(hash, msg)
    else
      call_local_torrent_proc(hash, msg)
    end
  end

  def call_local_torrent_proc(hash, msg) do
    name = get_name(hash)
    case :gproc.lookup_local_name(name) do
      :undefined ->
        {:ok, pid} = Supervisor.start_child(Aya.TorrentSupervisor, [hash, []])
        GenServer.call(pid, msg)
      pid -> GenServer.call(pid, msg)
    end
  end

  @doc """
  Acts as a router for determining which node should contain which torrent process.
  """
  def call_remote_torrent_proc(hash, msg) do
    name = get_name(hash)
    slice = String.slice(name, 0, 3)
    i1 = String.at(slice, 0) |> String.to_integer(16)
    i2 = String.at(slice, 1) |> String.to_integer(16)
    i3 = String.at(slice, 2) |> String.to_integer(16)
    :random.seed(i1, i2, i3)

    distributed_range = Application.get_env(:aya, :distributed_weight)
    rand = :random.uniform(distributed_range)

    nodes = Application.get_env(:aya, :distributed_nodes)
    {node, _range} = Enum.find(nodes, fn {_node, range} ->
      Enum.member(range, rand)
    end)

    case Node.ping(node) do
      :pong -> {:ok, resp} = :rpc.call(node, Aya.Util, :call_local_proc, [hash, msg])
      :pang ->
        require Logger
        Logger.log :warn, "Node #{node} is currently down! Launching local torrent instance to cover!"
        {:ok, resp} = call_local_torrent_proc(hash, msg)
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
