defmodule DesafioCli.CLITest do
  use ExUnit.Case
  import ExUnit.CaptureIO

  test "command output" do
    assert capture_io(fn -> DesafioCli.main([]) end) =~ ">"
  end

  # Adicione mais testes conforme necessário
end
