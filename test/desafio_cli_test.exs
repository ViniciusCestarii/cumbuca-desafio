defmodule DesafioCli.CLITest do
  use ExUnit.Case
  import ExUnit.CaptureIO

  test "command output" do
    assert capture_io(fn -> DesafioCli.main([]) end) =~ ">"
  end

  test "can't SET value with numeric key" do
    assert DesafioCli.Parser.parse_command("SET 1 teste") ==
             {:error, :syntax_error, "Numeric keys are not allowed"}
  end

  test "can't SET numeric value on key" do
    assert DesafioCli.Parser.parse_command("SET 12 teste") ==
             {:error, :syntax_error, "Numeric keys are not allowed"}
  end

  test "can SET key with spaces" do
    assert DesafioCli.Parser.parse_command("SET 'key with spaces' teste") ==
      {:ok, :set, "key with spaces", %{type: :string, value: "teste"}}
  end

  test "invalid command" do
    assert DesafioCli.Parser.parse_command("INVALID") ==
      {:error, "No command INVALID"}
  end
end
