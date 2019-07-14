defmodule ExBanking.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  def start(_type, _args) do

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    ExBanking.Supervisor.start_link()
  end
end
