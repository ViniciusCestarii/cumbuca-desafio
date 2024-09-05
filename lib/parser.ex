defmodule DesafioCli.Parser  do

  def parse_command(command) do
    case split_command(command) do
      ["SET", key, value] ->
        case parse_key_value(key, value) do
          {:ok, parsed_key, parsed_value} -> {:ok, :set, parsed_key, parsed_value}
          error -> error
        end

      ["GET", key] ->
        case parse_key(key) do
          {:ok, parsed_key} -> {:ok, :get, parsed_key}
          error -> error
        end

      ["BEGIN"] -> {:ok, :begin}
      ["COMMIT"] -> {:ok, :commit}
      ["ROLLBACK"] -> {:ok, :rollback}
      ["EXIT"] -> {:ok, :exit}
      ["SET", _] -> {:error, :syntax_error, "SET <chave> <valor>"}
      ["GET"] -> {:error, :syntax_error, "GET <chave>"}
      ["SET"] -> {:error, :syntax_error, "SET <chave> <valor>"}
      _ -> {:error, "Invalid command"}
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
      String.starts_with?(key, "'") and String.ends_with?(key, "'") -> {:ok, String.trim(key, "'")}
      String.contains?(key, " ") -> {:error, :syntax_error, "Keys cannot contain spaces"}
      String.match?(key, ~r/^\d+$/) -> {:error, :syntax_error, "Numeric keys are not allowed"}

      true -> {:ok, key}
    end
  end

  def parse_value(value) do
    cond do
      String.match?(value, ~r/^\d+$/) -> {:ok, String.to_integer(value)}
      String.starts_with?(value, "\"") and String.ends_with?(value, "\"") ->
        {:ok, String.trim(value, "\"")}
      true ->
        {:ok, value }
    end
  end

  def split_command(command) do
    command
    |> String.to_charlist()
    |> Enum.reduce({[], [], false, false}, fn char, {parts, current_part, is_inside_double_quotes, is_inside_simple_quote} ->
      case char do
        ?" ->
          {parts, current_part ++ [char], not is_inside_double_quotes, is_inside_simple_quote}

        ?' ->
          {parts, current_part ++ [char], is_inside_double_quotes, not is_inside_simple_quote}

        ?\s when not is_inside_double_quotes and not is_inside_simple_quote ->
          {parts ++ [List.to_string(current_part)], [], is_inside_double_quotes, is_inside_simple_quote}

        _ ->
          {parts, current_part ++ [char], is_inside_double_quotes, is_inside_simple_quote}
      end
    end)
    |> fn {parts, current_part, is_inside_double_quotes, is_inside_simple_quote} ->
      case is_inside_double_quotes or is_inside_simple_quote do
        true -> parts ++ String.split(List.to_string(current_part), " ")
        false -> parts ++ [List.to_string(current_part)]
      end
    end.()
  end
end
