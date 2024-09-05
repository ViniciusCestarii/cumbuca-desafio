defmodule DesafioCli.DB_Test do
  use ExUnit.Case

  setup do
    {:ok, _} = DesafioCli.DB.start_link()
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
end
