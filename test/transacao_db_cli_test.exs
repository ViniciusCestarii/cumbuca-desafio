defmodule DesafioCli.DB_Test do
  use ExUnit.Case

  setup do
    file_path = "test_db_state_#{:os.system_time(:millisecond)}.bin"

    {:ok, _} = DesafioCli.DB.start_link(file_path)

    on_exit(fn ->
      File.rm(file_path)
    end)

    :ok
  end

  test "GET non-existent key" do
    assert DesafioCli.DB.get("non_existent_key") == nil
  end

  test "GET existent key" do
    DesafioCli.DB.set("test_key", "test_value")
    assert DesafioCli.DB.get("test_key") == "test_value"
  end

  test "SET non-existent key" do
    assert DesafioCli.DB.set("non_existent_key", "test_value") == :ok
  end

  test "SET existent key" do
    DesafioCli.DB.set("test_key", "test_value")
    assert DesafioCli.DB.set("test_key", "test_value") == :ok
  end

  test "SET with key with spaces" do
    assert DesafioCli.DB.set("key with spaces", "test_value") == :ok
  end

  test "BEGIN" do
    assert DesafioCli.DB.begin() == :ok
  end

  test "ROLLBACK" do
    DesafioCli.DB.begin()
    assert DesafioCli.DB.rollback() == {:ok}
  end

  test "ROLLBACK with no transaction" do
    assert DesafioCli.DB.rollback() == {:error, :no_transaction_to_rollback}
  end

  test "ROLLBACK after SET" do
    DesafioCli.DB.begin()
    DesafioCli.DB.set("test_key", "test_value")
    assert DesafioCli.DB.rollback() == {:ok}
    assert DesafioCli.DB.get("test_key") == nil
  end

  test "COMMIT" do
    DesafioCli.DB.begin()
    assert DesafioCli.DB.commit() == {:ok}
  end

  test "COMMIT after SET" do
    DesafioCli.DB.begin()
    DesafioCli.DB.set("test_key", "test_value")
    assert DesafioCli.DB.commit() == {:ok}
    assert DesafioCli.DB.get("test_key") == "test_value"
  end

  test "COMMIT with no transaction" do
    assert DesafioCli.DB.commit() == {:error, :no_transaction_to_commit}
  end
end
