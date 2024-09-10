defmodule DesafioCli.TransactionsDB do
  @moduledoc """
  Um banco de dados chave-valor com suporte a transações recursivas e persistência em arquivo.
  """

  def start_link(db_file_path) do
    Agent.start_link(
      fn ->
        DesafioCli.PersistentDB.start_link(db_file_path)
        DesafioCli.PersistentDB.load_state()
      end,
      name: __MODULE__
    )
  end

  def set(key, value) do
    Agent.update(__MODULE__, fn state ->
      new_state = update_state(state, key, value)
      DesafioCli.PersistentDB.save_state(new_state)
      new_state
    end)
  end

  def get(key) do
    Agent.get(__MODULE__, fn state ->
      case Enum.find_value(state.txs, fn tx -> Map.get(tx, key) end) do
        :deleted -> nil
        nil -> Map.get(state.db, key, nil)
        value -> value
      end
    end)
  end

  def exists?(key) do
    Agent.get(__MODULE__, fn state ->
      exists_in_txs? = Enum.reduce_while(state.txs, {false, :not_deleted}, fn tx, acc ->
        case Map.fetch(tx, key) do
          {:ok, value} ->
            if is_deleted?(value) do
              {:halt, {true, :deleted}}
            else
              {:cont, {true, :not_deleted}}
            end
          :error ->
            {:cont, acc}
        end
      end)

      case exists_in_txs? do
        {true, :not_deleted} -> true
        {true, :deleted} -> false
        _ ->
          case Map.fetch(state.db, key) do
            {:ok, value} ->
              not is_deleted?(value)
            :error ->
              false
          end
      end
    end)
  end


  def delete?(key) do
    willDelete = exists?(key)

    if willDelete do
      Agent.update(__MODULE__, fn state ->
        new_state = update_state(state, key, :deleted)
        DesafioCli.PersistentDB.save_state(new_state)
        new_state
      end)
    end

    willDelete
  end

  def begin() do
    Agent.update(__MODULE__, fn state ->
      %{state | txs: [%{} | state.txs]}
    end)
  end

  def commit() do
    Agent.get_and_update(__MODULE__, fn state ->
      case state.txs do
        [current_tx | [previous_tx | rest]] ->
          merged_tx = merge_tx(previous_tx, current_tx)
          new_state = %{state | txs: [merged_tx | rest]}
          DesafioCli.PersistentDB.save_state(new_state)
          {{:ok}, new_state}

        [current_tx] ->
          new_db = merge_tx(state.db, current_tx)
          new_state = %{state | db: new_db, txs: []}
          DesafioCli.PersistentDB.save_state(new_state)
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
          DesafioCli.PersistentDB.save_state(new_state)
          {{:ok}, new_state}

        [] ->
          {{:error, :no_transaction_to_rollback}, state}
      end
    end)
  end

  def update_state(state, key, value) do
    case state.txs do
      [] ->
        case value do
          :deleted ->
            new_db = Map.delete(state.db, key)
            %{state | db: new_db}

          _ ->
            new_db = Map.put(state.db, key, value)
            %{state | db: new_db}
        end
      [current_tx | rest] ->
        new_tx = Map.put(current_tx, key, value)
        %{state | txs: [new_tx | rest]}
    end
  end

  defp merge_tx(tx1, tx2) do
    Map.merge(tx1, tx2, fn _, _, value2 ->
      if is_deleted?(value2) do
        nil
      else
        value2
      end
    end)
  end

  def get_transaction_stack_length() do
    Agent.get(__MODULE__, fn state -> length(state.txs) end)
  end

  defp is_deleted?(value) do
    value == :deleted
  end
end
