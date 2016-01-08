defmodule Aya.Driver do
  @moduledoc """
  Backend driver which is used with Aya. It should implement a set of functions
  which perform various forms of validation. These functions are:
  * `check_passkey` - Takes passkey, returns a user variable which will be used in future validation reqs
  * `check_torrent` - Validates a torrent hash and the previously defined user variable
  * `check_event` - Validates an event and the user variable
  * `handle_announce` - Handles a full announce request with new reported stats from a user
  """

  defmacro __using__(_args) do
    quote do
      use GenServer

      @type event :: :seeding | :leeching | :stopped
      @type hash :: String.t
      @type passkey :: String.t
      @type user :: any
      @type ul :: number
      @type dl :: number
      @type left :: number

      def start_link(opts \\ []) do
        {:ok, _pid} = GenServer.start_link(__MODULE__, :ok, opts)
      end

      defoverridable start_link: 1

      def init(:ok) do
        require Logger
        Logger.log :debug, "Started driver!"
        {:ok, []}
      end

      defoverridable init: 1

      def handle_call({:check_passkey, passkey}, _from, state) do
        {:reply, check_passkey(passkey), state}
      end

      @spec check_passkey(passkey) :: {:ok, user} | {:error, String.t}
      def check_passkey(_passkey) do
        {:ok, nil}
      end

      defoverridable check_passkey: 1

      def handle_call({:check_torrent, hash, user}, _from, state) do
        {:reply, check_torrent(hash, user), state}
      end

      @spec check_torrent(hash, user) :: :ok | {:error, String.t}
      def check_torrent(_hash, _user) do
        :ok
      end

      defoverridable check_torrent: 2

      def handle_call({:check_event, event, user}, _from, state) do
        {:reply, check_event(event, user), state}
      end

      @spec check_event(any, user) :: :ok | {:error, String.t}
      def check_event(_event, _user) do
        :ok
      end

      defoverridable check_event: 2

      def handle_cast({:announce, params, user}, state) do
        handle_announce(params, user)
        {:noreply, state}
      end

      @spec handle_announce({hash, ul, dl, left, event}, user) :: any
      def handle_announce(_params, _user) do
      end

      defoverridable handle_announce: 2
    end
  end
end
