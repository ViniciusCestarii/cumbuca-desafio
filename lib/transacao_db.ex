defmodule DesafioCli.DB do
  @moduledoc """
  Um banco de dados chave-valor com suporte a transações recursivas.
  """

  def start_link() do
    Agent.start_link(fn -> %{db: %{}, txs: [%{}]} end, name: __MODULE__)
  end

  def set(key, value) do
    Agent.update(__MODULE__, fn state ->
      current_tx = hd(state.txs)
      new_db = Map.put(current_tx, key, value)
      %{state | txs: [new_db | tl(state.txs)]}
    end)
  end

  def get(key) do
    Agent.get(__MODULE__, fn state ->
      Enum.find_value(state.txs, fn tx -> Map.get(tx, key, nil) end) || "NIL"
    end)
  end

  def begin() do
    Agent.update(__MODULE__, fn state ->
      current_tx = hd(state.txs) |> Map.merge(%{db: state.db})
      %{state | txs: [current_tx | state.txs]}
    end)
    :ok
  end

  def commit() do
    Agent.update(__MODULE__, fn state ->
      [current_tx | rest] = state.txs
      new_db = Map.merge(current_tx, state.db)
      %{state | db: new_db, txs: rest}
    end)
  end

  def rollback() do
    Agent.update(__MODULE__, fn state ->
      if length(state.txs) > 1 do
        [current_tx | rest] = state.txs
        %{state | txs: rest}
      else
        raise NoTransactionRollbackError
      end
    end)
  end

  def get_transaction_stack_length() do
    Agent.get(__MODULE__, fn state -> length(state.txs) - 1 end)
  end
end

defmodule NoTransactionRollbackError do
  defexception message: "no transaction to rollback"
end
