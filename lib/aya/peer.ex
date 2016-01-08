defmodule Aya.Peer do
  @moduledoc """
  Representation of a peer.
  """
  defstruct id: nil, ipv4: nil, ipv6: nil, port: nil, last_announce: nil, extra: %{}
end
