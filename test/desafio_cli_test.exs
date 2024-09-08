defmodule DesafioCli.CLITest do
  use ExUnit.Case
  import ExUnit.CaptureIO

  test "command output" do
    assert capture_io(fn -> DesafioCli.main([]) end) =~ ">"
  end

  test "invalid command output" do
    output =
      capture_io([input: "HELLO", capture_prompt: false], fn ->
        DesafioCli.main([])
      end)

    expected_output = "ERR \"No command HELLO\"\n"
    assert String.contains?(output, expected_output)
  end
end
