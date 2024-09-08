defmodule DesafioCli.TransactionsDB_Test do
  use ExUnit.Case

  setup do
    file_path = "test_db_state_#{:os.system_time(:millisecond)}.bin"

    {:ok, _} = DesafioCli.TransactionsDB.start_link(file_path)

    on_exit(fn ->
      File.rm(file_path)
    end)

    :ok
  end

  test "GET non-existent key" do
    assert DesafioCli.TransactionsDB.get("non_existent_key") == nil
  end

  test "GET existent key" do
    DesafioCli.TransactionsDB.set("test_key", "test_value")
    assert DesafioCli.TransactionsDB.get("test_key") == "test_value"
  end

  test "SET non-existent key" do
    assert DesafioCli.TransactionsDB.set("non_existent_key", "test_value") == :ok
  end

  test "SET existent key" do
    DesafioCli.TransactionsDB.set("test_key", "test_value")
    assert DesafioCli.TransactionsDB.set("test_key", "test_value") == :ok
  end

  test "SET with key with spaces" do
    assert DesafioCli.TransactionsDB.set("key with spaces", "test_value") == :ok
  end

  test "BEGIN" do
    assert DesafioCli.TransactionsDB.begin() == :ok
  end

  test "ROLLBACK" do
    DesafioCli.TransactionsDB.begin()
    assert DesafioCli.TransactionsDB.rollback() == {:ok}
  end

  test "ROLLBACK with no transaction" do
    assert DesafioCli.TransactionsDB.rollback() == {:error, :no_transaction_to_rollback}
  end

  test "ROLLBACK after SET" do
    DesafioCli.TransactionsDB.begin()
    DesafioCli.TransactionsDB.set("test_key", "test_value")
    assert DesafioCli.TransactionsDB.rollback() == {:ok}
    assert DesafioCli.TransactionsDB.get("test_key") == nil
  end

  test "COMMIT" do
    DesafioCli.TransactionsDB.begin()
    assert DesafioCli.TransactionsDB.commit() == {:ok}
  end

  test "COMMIT after SET" do
    DesafioCli.TransactionsDB.begin()
    DesafioCli.TransactionsDB.set("test_key", "test_value")
    assert DesafioCli.TransactionsDB.commit() == {:ok}
    assert DesafioCli.TransactionsDB.get("test_key") == "test_value"
  end

  test "COMMIT with no transaction" do
    assert DesafioCli.TransactionsDB.commit() == {:error, :no_transaction_to_commit}
  end
end
