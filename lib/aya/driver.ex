defmodule Aya.Driver do
  @moduledoc """
  Backend driver which is used with Aya. It should implement a set of functions
  which perform various forms of validation. These functions are:
  * `check_passkey` - Takes passkey, returns a user variable which will be used in future validation reqs
  * `check_torrent` - Validates a torrent hash and the previously defined user variable
  * `check_event` - Validates an event and the user variable
  * `handle_announce` - Handles a full announce request with new reported stats from a user

  All driver functions are simply sugar around standard GenServer calls. They will
  all be passed a state variable and should return a response in the form {response, new_state}.
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
      @type state :: any

      def start_link(opts \\ []) do
        {:ok, _pid} = GenServer.start_link(__MODULE__, :ok, opts)
      end

      defoverridable start_link: 1

      def init(:ok) do
        require Logger
        Logger.log :debug, "Started driver!"
        {:ok, nil}
      end

      defoverridable init: 1

      def handle_call({:check_passkey, passkey}, _from, state) do
        {reply, new_state} = check_passkey(passkey, state)
        {:reply, reply, new_state}
      end

      @spec check_passkey(passkey, state) :: {{:ok, user}, state} | {{:error, String.t}, state}
      def check_passkey(_passkey, state) do
        {{:ok, nil}, state}
      end

      defoverridable check_passkey: 2

      def handle_call({:check_torrent, hash, user}, _from, state) do
        {reply, new_state} = check_torrent(hash, user, state)
        {:reply, reply, new_state}
      end

      @spec check_torrent(hash, user, state) :: {:ok, state} | {{:error, String.t}, state}
      def check_torrent(_hash, _user, state) do
        {:ok, state}
      end

      defoverridable check_torrent: 3

      def handle_call({:check_event, event, user}, _from, state) do
        {reply, new_state} = check_event(event, user, state)
        {:reply, reply, new_state}
      end

      @spec check_event(any, user, state) :: {:ok, state} | {{:error, String.t}, state}
      def check_event(_event, _user, state) do
        {:ok, state}
      end

      defoverridable check_event: 3

      def handle_call({:announce, params, user}, _from, state) do
        new_state = handle_announce(params, user, state)
        {:reply, :ok, state}
      end

      @spec handle_announce({hash, ul, dl, left, event}, user, state) :: state
      def handle_announce(_params, _user, state) do
        state
      end

      defoverridable handle_announce: 3
    end
  end
end
