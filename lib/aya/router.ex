defmodule Aya.Router do
  use Plug.Router

  plug Plug.Logger, log: :debug
  plug :match
  plug :dispatch

  if Application.get_env(:aya, :require_passkey, false) do
    get "/:passkey/announce" do
      case GenServer.call(Aya.Driver, {:check_passkey, passkey}) do
        {:ok, user} -> Aya.Announce.handle(conn, user)
        {:error, reason} -> Aya.Util.bad_request(conn, reason)
      end
    end

    get "/:passkey/scrape" do
      case GenServer.call(Aya.Driver, {:check_passkey, passkey}) do
        {:ok, user} -> Aya.Scrape.handle(conn, user)
        {:error, reason} -> Aya.Util.bad_request(conn, reason)
      end
    end
  else
    get "/announce" do
      Aya.Announce.handle(conn)
    end

    get "/scrape" do
      Aya.Scrape.handle(conn)
    end
  end

  match _ do
    Aya.Util.bad_request(conn, "Invalid URL", 404)
  end

end
