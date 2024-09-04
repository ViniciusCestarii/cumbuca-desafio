defmodule DesafioCli  do
  def main(_args) do
    start_db()
    loop()
  end

  defp start_db() do
    {:ok, _} = DesafioCli.DB.start_link()
  end

  defp loop() do
    IO.write("> ")
    command = IO.gets("") |> String.trim()
    case parse_command(command) do
      {:ok, :set, key, value} -> handle_set(key, value)
      {:ok, :get, key} -> handle_get(key)
      {:ok, :begin} -> handle_begin()
      {:ok, :commit} -> handle_commit()
      {:ok, :rollback} -> handle_rollback()
      {:error, message} -> IO.puts("ERR #{message}")
    end
    loop()
  end

  defp parse_command(command) do
    case String.split(command, " ") do
      ["SET", key, value] -> {:ok, :set, key, value}
      ["GET", key] -> {:ok, :get, key}
      ["BEGIN"] -> {:ok, :begin}
      ["COMMIT"] -> {:ok, :commit}
      ["ROLLBACK"] -> {:ok, :rollback}
      _ -> {:error, "Invalid command or syntax error"}
    end
  end

  defp handle_set(key, value) do
    old_value = DesafioCli.DB.get(key)
    DesafioCli.DB.set(key, value)
    case old_value do
      "NIL" -> IO.puts("FALSE #{value}")
      old_value -> IO.puts("TRUE #{value}")
    end
  end

  defp handle_get(key) do
    IO.puts(DesafioCli.DB.get(key))
  end

  defp handle_begin() do
    DesafioCli.DB.begin()
    nesting_level = DesafioCli.DB.get_transaction_stack_length()
    IO.puts(nesting_level)
  end

  defp handle_commit() do
    DesafioCli.DB.commit()
    nesting_level = DesafioCli.DB.get_transaction_stack_length()
    IO.puts(nesting_level)
  end

  defp handle_rollback() do
    try do
      DesafioCli.DB.rollback()
      nesting_level = DesafioCli.DB.get_transaction_stack_length()
      IO.puts(nesting_level)
    rescue
      e in NoTransactionRollbackError -> IO.puts("ERR #{e.message}")
    end
  end

end
