defmodule DesafioCliTest do
  use ExUnit.Case

  setup do
    {:ok, _} = DesafioCli.DB.start_link()
    :ok
  end

  test "SET and GET commands" do
    DesafioCli.DB.set("test_key", "test_value")
    assert DesafioCli.DB.get("test_key") == "test_value"
  end

  # Adicione mais testes conforme necessário
end
