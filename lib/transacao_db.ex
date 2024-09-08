defmodule DesafioCli.DB do
  @moduledoc """
  Um banco de dados chave-valor com suporte a transações recursivas e persistência em arquivo.
  """

  @file_path "db_state.bin"

  def start_link() do
    Agent.start_link(fn -> load_state() end, name: __MODULE__)
  end

  def set(key, value) do
    Agent.update(__MODULE__, fn state ->
      new_state = update_state(state, key, value)
      save_state(new_state)
      new_state
    end)
  end

  def get(key) do
    Agent.get(__MODULE__, fn state ->
      value = Enum.find_value(state.txs, fn tx -> Map.get(tx, key) end)
      value || Map.get(state.db, key, nil)
    end)
  end

  def begin() do
    Agent.update(__MODULE__, fn state ->
      %{state | txs: [%{} | state.txs]}
    end)
    :ok
  end

  def commit() do
    Agent.get_and_update(__MODULE__, fn state ->
      case state.txs do
        [current_tx | [previous_tx | rest]] ->
          merged_tx = Map.merge(previous_tx, current_tx)
          new_state = %{state | txs: [merged_tx | rest]}
          save_state(new_state)
          {{:ok}, new_state}

        [current_tx] ->
          new_db = Map.merge(state.db, current_tx)
          new_state = %{state | db: new_db, txs: []}
          save_state(new_state)
          {{:ok}, new_state}

        [] ->
          {{:error, :no_transaction_to_commit}, state}
      end
    end)
  end

  def rollback() do
    Agent.get_and_update(__MODULE__, fn state ->
      case state.txs do
        [_ | rest] ->
          new_state = %{state | txs: rest}
          save_state(new_state)
          {{:ok}, new_state}

        [] ->
          {{:error, :no_transaction_to_rollback}, state}
      end
    end)
  end

  def get_transaction_stack_length() do
    Agent.get(__MODULE__, fn state -> length(state.txs) end)
  end

  defp update_state(state, key, value) do
    case state.txs do
      [] ->
        new_db = Map.put(state.db, key, value)
        %{state | db: new_db}

      [current_tx | rest] ->
        new_tx = Map.put(current_tx, key, value)
        %{state | txs: [new_tx | rest]}
    end
  end

  defp save_state(state) do
    binary_data = :erlang.term_to_binary(state.db)
    File.write!(@file_path, binary_data)
  end

  defp load_state() do
    case File.read(@file_path) do
      {:ok, binary_data} ->
        db =
          case :erlang.binary_to_term(binary_data) do
            %{} = map -> map
            _ -> %{}
          end

        %{db: db, txs: []}

      {:error, _} ->
        %{db: %{}, txs: []}
    end
  end
end
