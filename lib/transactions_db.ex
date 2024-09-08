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
      value = Enum.find_value(state.txs, fn tx -> Map.get(tx, key) end)
      value || Map.get(state.db, key, nil)
    end)
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
          merged_tx = Map.merge(previous_tx, current_tx)
          new_state = %{state | txs: [merged_tx | rest]}
          DesafioCli.PersistentDB.save_state(new_state)
          {{:ok}, new_state}

        [current_tx] ->
          new_db = Map.merge(state.db, current_tx)
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
        new_db = Map.put(state.db, key, value)
        %{state | db: new_db}

      [current_tx | rest] ->
        new_tx = Map.put(current_tx, key, value)
        %{state | txs: [new_tx | rest]}
    end
  end

  def get_transaction_stack_length() do
    Agent.get(__MODULE__, fn state -> length(state.txs) end)
  end
end
