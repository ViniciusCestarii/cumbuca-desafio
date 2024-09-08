defmodule DesafioCli do
  def main(_args) do
    start_db()
    loop()
  end

  @db_file_path "db_state.bin"
  defp start_db() do
    {:ok, _} = DesafioCli.TransactionsDB.start_link(@db_file_path)
  end

  def loop() do
    IO.write("> ")
    command = IO.gets("")

    case command do
      :eof ->
        IO.puts("End of input detected. Exiting...")
        :ok

      _ ->
        command = command |> String.trim()

        case DesafioCli.Parser.parse_command(command) do
          {:ok, :set, key, value} ->
            handle_set(key, value)

          {:ok, :get, key} ->
            handle_get(key)

          {:ok, :begin} ->
            handle_begin()

          {:ok, :commit} ->
            handle_commit()

          {:ok, :rollback} ->
            handle_rollback()

          {:ok, :exit} ->
            IO.puts("Exiting...")

          {:error, :syntax_error, message} ->
            handle_error("#{message} - Syntax error")

          {:error, message} ->
            handle_error(message)
        end

        unless command == "EXIT" do
          loop()
        end
    end
  end

  defp handle_set(key, value_data) do
    old_value = DesafioCli.TransactionsDB.get(key)
    DesafioCli.TransactionsDB.set(key, DesafioCli.Transformer.to_model_value(value_data))

    case old_value do
      nil -> IO.puts("FALSE #{value_data.value}")
      ^old_value -> IO.puts("TRUE #{value_data.value}")
    end
  end

  defp handle_get(key) do
    case DesafioCli.TransactionsDB.get(key) do
      nil ->
        IO.puts("NIL")

      db_value ->
        case DesafioCli.Parser.parse_value(db_value) do
          {:ok, value_data} -> IO.puts("#{value_data.value} #{value_data.type}")
          {:error, message} -> handle_error(message)
        end
    end
  end

  defp handle_begin() do
    DesafioCli.TransactionsDB.begin()
    print_transaction_stack_length()
  end

  defp handle_commit() do
    case DesafioCli.TransactionsDB.commit() do
      {:ok} -> print_transaction_stack_length()
      {:error, :no_transaction_to_commit} -> handle_error("No transaction to commit")
    end
  end

  defp handle_rollback() do
    case DesafioCli.TransactionsDB.rollback() do
      {:ok} -> print_transaction_stack_length()
      {:error, :no_transaction_to_rollback} -> handle_error("No transaction to rollback")
    end
  end

  defp handle_error(message) do
    IO.puts("ERR \"#{message}\"")
  end

  defp print_transaction_stack_length() do
    nesting_level = DesafioCli.TransactionsDB.get_transaction_stack_length()
    IO.puts(nesting_level)
  end
end
