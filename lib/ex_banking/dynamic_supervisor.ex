defmodule ExBanking.DynamicSupervisor do
  @moduledoc false

  use DynamicSupervisor

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

  def start_link() do
    DynamicSupervisor.start_link(__MODULE__, [], name: __MODULE__)
  end

  @spec create_user(user :: String.t()) :: :ok | banking_error
  def create_user(user) do
    case DynamicSupervisor.start_child(
           ExBanking.DynamicSupervisor,
           %{
             :id => user,
             :start => {ExBanking.Worker, :start_link, [String.to_atom(user)]}
           }
         ) do
      {:ok, _} -> :ok
      {:error, {:already_started, _}} -> :user_already_exists
    end
  end

  def init(_arg) do
    DynamicSupervisor.init(strategy: :one_for_one)
  end
end
