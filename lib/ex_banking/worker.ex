defmodule ExBanking.Worker do
  @moduledoc false

  @type banking_error ::
          {:error,
           :wrong_arguments
           | :user_already_exists
           | :user_does_not_exist
           | :not_enough_money
           | :sender_does_not_exist
           | :receiver_does_not_exist
           | :too_many_requests_to_user
           | :too_many_requests_to_sender
           | :too_many_requests_to_receiver}

  use GenServer

  def start_link(name) do
    GenServer.start_link(__MODULE__, %{}, name: name)
  end

  @spec deposit(user :: String.t(), amount :: number, currency :: String.t()) ::
          {:ok, new_balance :: number} | banking_error
  def deposit(user, amount, currency) do
    case get_messages_number(user) do
      :user_does_not_exist ->
        :user_does_not_exist

      messages when messages > 10 ->
        :too_many_requests_to_user

      _messages ->
        GenServer.call(String.to_atom(user), {:deposit, String.to_atom(currency), amount})
    end
  end

  @spec withdraw(user :: String.t(), amount :: number, currency :: String.t()) ::
          {:ok, new_balance :: number} | banking_error
  def withdraw(user, amount, currency) do
    case get_messages_number(user) do
      :user_does_not_exist ->
        :user_does_not_exist

      messages when messages > 10 ->
        :too_many_requests_to_user

      _messages ->
        GenServer.call(String.to_atom(user), {:withdraw, String.to_atom(currency), amount})
    end
  end

  @spec get_balance(user :: String.t(), currency :: String.t()) ::
          {:ok, balance :: number} | banking_error
  def get_balance(user, currency) do
    case get_messages_number(user) do
      :user_does_not_exist -> :user_does_not_exist
      messages when messages > 10 -> :too_many_requests_to_user
      _messages -> GenServer.call(String.to_atom(user), {:get_balance, String.to_atom(currency)})
    end
  end

  @spec send(
          from_user :: String.t(),
          to_user :: String.t(),
          amount :: number,
          currency :: String.t()
        ) :: {:ok, from_user_balance :: number, to_user_balance :: number} | banking_error
  def send(from_user, to_user, amount, currency) do
    case get_messages_number(from_user) do
      :user_does_not_exist ->
        :sender_does_not_exist

      messages when messages > 10 ->
        :too_many_requests_to_sender

      _messages ->
        case get_messages_number(to_user) do
          :user_does_not_exist -> :receiver_does_not_exist
          messages when messages > 10 -> :too_many_requests_to_receiver
          _messages -> send_money(from_user, to_user, amount, currency)
        end
    end
  end

  @spec get_messages_number(user :: String.t()) :: number
  defp get_messages_number(user) do
    try do
      {:status, pid, _, _} = :sys.get_status(String.to_atom(user))
      {:message_queue_len, messages} = :erlang.process_info(pid, :message_queue_len)
      messages
    catch
      :exit, _ -> :user_does_not_exist
    end
  end

  @spec send_money(
          from_user :: String.t(),
          to_user :: String.t(),
          amount :: number,
          currency :: String.t()
        ) :: {:ok, from_user_balance :: number, to_user_balance :: number} | banking_error
  defp send_money(from_user, to_user, amount, currency) do
    case GenServer.call(String.to_atom(from_user), {:withdraw, String.to_atom(currency), amount}) do
      :not_enough_money ->
        :not_enough_money

      {:ok, from_user_balance} ->
        {:ok, to_user_balance} =
          GenServer.call(String.to_atom(to_user), {:deposit, String.to_atom(currency), amount})

        {:ok, from_user_balance, to_user_balance}
    end
  end

  def init(state) do
    {:ok, state}
  end

  def handle_call({:deposit, currency, amount}, _from, state) do
    state =
      case state[currency] do
        nil -> Map.put(state, currency, amount)
        old_amount -> %{state | currency => old_amount + amount}
      end

    {:reply, {:ok, Float.floor(state[currency] / 1, 2)}, state}
  end

  def handle_call({:withdraw, currency, amount}, _from, state) do
    case state[currency] do
      nil ->
        {:reply, :not_enough_money, state}

      old_amount when old_amount < amount ->
        {:reply, :not_enough_money, state}

      old_amount ->
        state = %{state | currency => old_amount - amount}
        {:reply, {:ok, Float.floor(state[currency] / 1, 2)}, state}
    end
  end

  def handle_call({:get_balance, currency}, _from, state) do
    case state[currency] do
      nil -> {:reply, :wrong_arguments, state}
      amount -> {:reply, {:ok, Float.floor(amount / 1, 2)}, state}
    end
  end

  def handle_call(_msg, _from, state) do
    {:reply, :ok, state}
  end

  def handle_cast(_msg, state) do
    {:noreply, state}
  end
end
