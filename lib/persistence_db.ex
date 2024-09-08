defmodule DesafioCli.Persistence do
  def start_link(db_file_path) do
    Agent.start_link(
      fn ->
        db_file_path
      end,
      name: __MODULE__
    )
  end

  def set_db_file_path(db_file_path) do
    Agent.update(__MODULE__, fn _old_path -> db_file_path end)
  end

  def get_db_file_path() do
    Agent.get(__MODULE__, fn db_file_path -> db_file_path end)
  end

  def save_state(state) do
    db_file_path = get_db_file_path()
    binary_data = :erlang.term_to_binary(state.db)
    File.write!(db_file_path, binary_data)
  end

  def load_state() do
    db_file_path = get_db_file_path()
    case File.read(db_file_path) do
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
