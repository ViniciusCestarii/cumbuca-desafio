defmodule DesafioCli.CLITest do
  use ExUnit.Case
  import ExUnit.CaptureIO

  test "command output" do
    assert capture_io(fn -> DesafioCli.main([]) end) =~ ">"
  end

  test "can't SET value with numeric key" do
    assert DesafioCli.Parser.parse_command("SET 1 teste") == {:error, :syntax_error, "Numeric keys are not allowed"}
  end
end
