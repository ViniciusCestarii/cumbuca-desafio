defmodule DesafioCli.Parser do
  def parse_command(command) do
    case split_command(command) do
      ["SET", key, value] ->
        case parse_key_value(key, value) do
          {:ok, parsed_key, parsed_value} -> {:ok, :set, parsed_key, parsed_value}
          error -> case value == "NIL" do
            true -> {:error, :syntax_error, "NIL is not a valid value - use DELETE <chave> instead"}
            _ -> error
          end
        end

      ["GET", key] ->
        case parse_key(key) do
          {:ok, parsed_key} -> {:ok, :get, parsed_key}
          error -> error
        end

      ["EXISTS", key] ->
        case parse_key(key) do
          {:ok, parsed_key} -> {:ok, :exists, parsed_key}
          error -> error
        end

      ["DELETE", key] ->
        case parse_key(key) do
          {:ok, parsed_key} -> {:ok, :delete, parsed_key}
          error -> error
        end

      ["BEGIN"] ->
        {:ok, :begin}

      ["COMMIT"] ->
        {:ok, :commit}

      ["ROLLBACK"] ->
        {:ok, :rollback}

      ["EXIT"] ->
        {:ok, :exit}

      ["SET" | _] ->
        {:error, :syntax_error, "SET <chave> <valor>"}

      ["GET" | _] ->
        {:error, :syntax_error, "GET <chave>"}

      ["EXISTS" | _] ->
        {:error, :syntax_error, "EXISTS <chave>"}

      ["DELETE" | _] ->
        {:error, :syntax_error, "DELETE <chave>"}

      ["BEGIN" | _] ->
        {:error, :syntax_error, "BEGIN"}

      ["COMMIT" | _] ->
        {:error, :syntax_error, "COMMIT"}

      ["ROLLBACK" | _] ->
        {:error, :syntax_error, "ROLLBACK"}

      ["EXIT" | _] ->
        {:error, :syntax_error, "EXIT"}

      [invalid_command | _] ->
        {:error, "No command #{invalid_command}"}

      [ ] ->
        {:error, "Write a command"}
    end
  end

  def parse_key_value(key, value) do
    with {:ok, parsed_key} <- parse_key(key),
         {:ok, parsed_value} <- parse_value(value) do
      {:ok, parsed_key, parsed_value}
    else
      error -> error
    end
  end

  def parse_key(key) do
    cond do
      String.starts_with?(key, "'") and String.ends_with?(key, "'") ->
        trimmed_key = String.slice(key, 1..-2//1)
        {:ok, trimmed_key}

      String.contains?(key, " ") ->
        {:error, :syntax_error, "Keys cannot contain spaces"}

      String.match?(key, ~r/^\d+$/) ->
        {:error, :syntax_error, "Numeric keys are not allowed"}

      true ->
        {:ok, key}
    end
  end

  def parse_value(value) do
    value = to_string(value)

    cond do
      is_number_string(value) ->
        {:ok, %{value: value, type: :number}}

      is_boolean_string(value) ->
        {:ok, %{value: value, type: :boolean}}

      is_string_with_backslash(value) ->
        trimmed_value = String.slice(value, 1..-2//1)
        {:ok, %{value: trimmed_value, type: :string}}

      is_nil_string(value) ->
        {:error, :syntax_error, "NIL is not a valid value"}

      true ->
        {:ok, %{value: value, type: :string}}
    end
  end

  defp is_number_string(value) do
    String.match?(value, ~r/^\d+$/)
  end

  defp is_boolean_string(value) do
    value in ["TRUE", "FALSE"]
  end

  defp is_string_with_backslash(value) do
    String.starts_with?(value, "\"") and String.ends_with?(value, "\"")
  end

  defp is_nil_string(value) do
    value == "NIL"
  end

  def split_command(command) do
    command
    # Temporarily replace escaped quotes
    |> String.replace(~r/\\\"/, "\u00AB")
    # Match quoted strings and regular words separately
    |> String.split(~r/(?<!\\)\s+(?=(?:[^"']*(["'])(?:\\.|(?!\1).)*\1)*[^"']*$)/, trim: true)
    # Remove any extra spaces
    |> Enum.map(&String.trim/1)
    # Restore escaped quotes
    |> Enum.map(&String.replace(&1, "\u00AB", "\""))
  end
end
