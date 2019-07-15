defmodule ExBankingTest do
  use ExUnit.Case
  doctest ExBanking

  test "all tests" do
    assert ExBanking.create_user("Test") == :ok
    assert ExBanking.create_user("Test1") == :ok
    assert ExBanking.create_user("Test") == :user_already_exists
    assert ExBanking.deposit("Test", 10, "USD") == { :ok, 10 }
    assert ExBanking.deposit("Test", 10, "RUB") == { :ok, 10 }
    assert ExBanking.deposit("ABCD", 10, "USD") == :user_does_not_exist
    assert ExBanking.withdraw("ABCD", 10, "USD") == :user_does_not_exist
    assert ExBanking.withdraw("Test", 1.4517, "USD") == { :ok, 8.54 }
    assert ExBanking.withdraw("Test", 10.4517, "USD") == :not_enough_money
    assert ExBanking.send("Test", "Test1", 2.347, "USD") == { :ok, 6.2, 2.34 }
    assert ExBanking.send("ABCD", "Test1", 2.347, "USD") == :sender_does_not_exist
    assert ExBanking.send("Test1", "ABCD", 2.347, "USD") == :receiver_does_not_exist
    assert ExBanking.get_balance("Test", "USD") == { :ok, 6.2 }
    assert ExBanking.get_balance("Test", "RUB") == { :ok, 10 }
    assert ExBanking.get_balance("Test", "ABCD") == :wrong_arguments
  end
end
