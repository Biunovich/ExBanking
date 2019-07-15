defmodule ExBanking.Worker do
  @moduledoc false
  


  use GenServer

  def start_link(name) do
    GenServer.start_link(__MODULE__, %{}, name: name)
  end

  def init(state) do
    {:ok, state}
  end

  def handle_call({ :deposit, currency, amount }, _from, state) do
    state = case state[currency] do
      nil -> Map.put(state, currency, amount)
      old_amount -> %{state | currency => old_amount + amount}
    end
    {:reply, { :ok, Float.floor(state[currency]/1, 2) }, state}
  end

  def handle_call({ :withdraw, currency, amount }, _from, state) do
    case state[currency] do
      nil -> {:reply, :not_enough_money, state}
      old_amount when old_amount < amount -> {:reply, :not_enough_money, state}
      old_amount ->
        state = %{state | currency => old_amount - amount}
        {:reply, { :ok, Float.floor(state[currency]/1, 2) }, state}
    end
  end

  def handle_call({ :get_balance, currency }, _from, state) do
    case state[currency] do
      nil -> {:reply, :wrong_arguments, state}
      amount -> {:reply, { :ok, Float.floor(amount/1, 2) }, state}
    end
  end

  def handle_call(_msg, _from, state) do
    {:reply, :ok, state}
  end

  def handle_cast(_msg, state) do
    {:noreply, state}
  end
end