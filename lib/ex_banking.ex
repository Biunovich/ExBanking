defmodule ExBanking do
  @moduledoc """
  Documentation for ExBanking.
  """

  @type banking_error :: {:error,
                           :wrong_arguments                |
                           :user_already_exists            |
                           :user_does_not_exist            |
                           :not_enough_money               |
                           :sender_does_not_exist          |
                           :receiver_does_not_exist        |
                           :too_many_requests_to_user      |
                           :too_many_requests_to_sender    |
                           :too_many_requests_to_receiver
                         }

  @spec get_messages_number(user :: String.t) :: number
  defp get_messages_number(user) do
    try do
      { :status, pid, _, _ } = :sys.get_status(String.to_atom(user))
      { :message_queue_len, messages } = :erlang.process_info(pid, :message_queue_len)
    messages
    catch
      :exit, _ -> :user_does_not_exist
    end
  end

  @spec send_money(from_user :: String.t, to_user :: String.t, amount :: number, currency :: String.t) :: {:ok, from_user_balance :: number, to_user_balance :: number} | banking_error
  defp send_money(from_user, to_user, amount, currency) do
    case GenServer.call(String.to_atom(from_user), { :withdraw, String.to_atom(currency), amount }) do
      :not_enough_money -> :not_enough_money
      {:ok, from_user_balance} ->
        { :ok, to_user_balance } = GenServer.call(String.to_atom(to_user), { :deposit, String.to_atom(currency), amount })
        { :ok, from_user_balance, to_user_balance }
    end
  end

  @spec create_user(user :: String.t) :: :ok | banking_error
  def create_user(user) do
    case DynamicSupervisor.start_child(ExBanking.DynamicSupervisor,
      %{
        :id => user,
        :start => { ExBanking.Worker, :start_link, [String.to_atom(user)] }
      }) do
      { :ok, _ } -> :ok
      { :error, { :already_started, _ } } -> :user_already_exists
    end
  end

  @spec deposit(user :: String.t, amount :: number, currency :: String.t) :: {:ok, new_balance :: number} | banking_error
  def deposit(user, amount, currency) do
    case get_messages_number(user) do
      :user_does_not_exist -> :user_does_not_exist
      messages when messages > 10 -> :too_many_requests_to_user
      _messages -> GenServer.call(String.to_atom(user), { :deposit, String.to_atom(currency), amount })
    end
  end

  @spec withdraw(user :: String.t, amount :: number, currency :: String.t) :: {:ok, new_balance :: number} | banking_error
  def withdraw(user, amount, currency) do
    case get_messages_number(user) do
      :user_does_not_exist -> :user_does_not_exist
      messages when messages > 10 -> :too_many_requests_to_user
      _messages -> GenServer.call(String.to_atom(user), { :withdraw, String.to_atom(currency), amount })
    end
  end

  @spec get_balance(user :: String.t, currency :: String.t) :: {:ok, balance :: number} | banking_error
  def get_balance(user, currency) do
    case get_messages_number(user) do
      :user_does_not_exist -> :user_does_not_exist
      messages when messages > 10 -> :too_many_requests_to_user
      _messages -> GenServer.call(String.to_atom(user), { :get_balance, String.to_atom(currency) })
    end
  end

  @spec send(from_user :: String.t, to_user :: String.t, amount :: number, currency :: String.t) :: {:ok, from_user_balance :: number, to_user_balance :: number} | banking_error
  def send(from_user, to_user, amount, currency) do
    case get_messages_number(from_user) do
      :user_does_not_exist -> :sender_does_not_exist
      messages when messages > 10 -> :too_many_requests_to_sender
      _messages ->
        case get_messages_number(to_user) do
          :user_does_not_exist -> :receiver_does_not_exist
          messages when messages > 10 -> :too_many_requests_to_receiver
          _messages -> send_money(from_user, to_user, amount, currency)
        end
    end
  end

end
