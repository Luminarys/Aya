defmodule Aya.Router do
  use Plug.Router

  plug Plug.Logger, log: :debug
  plug :match
  plug :dispatch

  if Application.get_env(:aya, :require_passkey, false) do
    get "/:passkey/announce" do
      driver = :poolboy.checkout(:driver_pool)
      response = case GenServer.call(driver, {:check_passkey, passkey}) do
        {:ok, user} -> Aya.Announce.handle(conn, user)
        {:error, reason} -> Aya.Util.bad_request(conn, reason)
      end
      :poolboy.checkin(:driver_pool, driver)
      response
    end

    get "/:passkey/scrape" do
      driver = :poolboy.checkout(:driver_pool)
      response = case GenServer.call(driver, {:check_passkey, passkey}) do
        {:ok, user} -> Aya.Scrape.handle(conn, user)
        {:error, reason} -> Aya.Util.bad_request(conn, reason)
      end
      :poolboy.checkin(:driver_pool, driver)
      response
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
