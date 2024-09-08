defmodule DesafioCli.CLITest do
  use ExUnit.Case
  import ExUnit.CaptureIO

  setup do
    file_path = "test_db_state_#{:os.system_time(:millisecond)}.bin"

    {:ok, _} = DesafioCli.TransactionsDB.start_link(file_path)

    on_exit(fn ->
      File.rm(file_path)
    end)

    :ok
  end

  defp extract_relevant_output(output) do
    case String.split(output, "> End of input detected. Exiting...", parts: 2) do
      [relevant_output | _] -> relevant_output
      _ -> output
    end
  end

  test "command output" do
    assert capture_io(fn -> DesafioCli.loop() end) =~ ">"
  end

  test "invalid command output" do
    output =
      capture_io([input: "HELLO", capture_prompt: false], fn ->
        DesafioCli.loop()
      end)

    expected_output = "> ERR \"No command HELLO\"\n"

    assert extract_relevant_output(output) == expected_output
  end

  test "exit command output" do
    output =
      capture_io([input: "EXIT", capture_prompt: false], fn ->
        DesafioCli.loop()
      end)

    expected_output = "> Exiting...\n"
    assert extract_relevant_output(output) == expected_output
  end

  test "SET command output" do
    output =
      capture_io([input: "SET 'key' value", capture_prompt: false], fn ->
        DesafioCli.loop()
      end)

    expected_output = "> FALSE value\n"
    assert extract_relevant_output(output) == expected_output
  end

  test "SET command output with key with spaces" do
    output =
      capture_io([input: "SET 'key with spaces' 'value'", capture_prompt: false], fn ->
        DesafioCli.loop()
      end)

    expected_output = "> FALSE 'value'\n"
    assert extract_relevant_output(output) == expected_output
  end

  test "SET command output with value with spaces" do
    output =
      capture_io(
        [input: "SET 'key with spaces' \"value and more value\"", capture_prompt: false],
        fn ->
          DesafioCli.loop()
        end
      )

    expected_output = "> FALSE value and more value\n"
    assert extract_relevant_output(output) == expected_output
  end

  test "invalid SET command output" do
    output =
      capture_io([input: "SET nova-value", capture_prompt: false], fn ->
        DesafioCli.loop()
      end)

    expected_output = "> ERR \"SET <chave> <valor> - Syntax error\"\n"
    assert extract_relevant_output(output) == expected_output
  end

  test "GET command output" do
    output =
      capture_io([input: "GET 'key'", capture_prompt: false], fn ->
        DesafioCli.loop()
      end)

    expected_output = "> NIL\n"
    assert extract_relevant_output(output) == expected_output
  end

  test "GET command output with key with spaces" do
    capture_io([input: "SET 'key with spaces' value", capture_prompt: false], fn ->
      DesafioCli.loop()
    end)

    output =
      capture_io([input: "GET 'key with spaces'", capture_prompt: false], fn ->
        DesafioCli.loop()
      end)

    expected_output = "> value string\n"
    assert extract_relevant_output(output) == expected_output
  end

  test "invalid GET command output" do
    output =
      capture_io([input: "GET", capture_prompt: false], fn ->
        DesafioCli.loop()
      end)

    expected_output = "> ERR \"GET <chave> - Syntax error\"\n"
    assert extract_relevant_output(output) == expected_output
  end

  test "BEGIN command output" do
    output =
      capture_io([input: "BEGIN", capture_prompt: false], fn ->
        DesafioCli.loop()
      end)

    expected_output = "> 1\n"
    assert extract_relevant_output(output) == expected_output

    output =
      capture_io([input: "BEGIN", capture_prompt: false], fn ->
        DesafioCli.loop()
      end)

    expected_output = "> 2\n"

    assert extract_relevant_output(output) == expected_output
  end

  test "COMMIT command output" do
    output =
      capture_io([input: "COMMIT", capture_prompt: false], fn ->
        DesafioCli.loop()
      end)

    expected_output = "> ERR \"No transaction to commit\"\n"
    assert extract_relevant_output(output) == expected_output

    capture_io([input: "BEGIN", capture_prompt: false], fn ->
      DesafioCli.loop()
    end)

    output =
      capture_io([input: "COMMIT", capture_prompt: false], fn ->
        DesafioCli.loop()
      end)

    expected_output = "> 0\n"

    assert extract_relevant_output(output) == expected_output
  end

  test "ROLLBACK command output" do
    output =
      capture_io([input: "ROLLBACK", capture_prompt: false], fn ->
        DesafioCli.loop()
      end)

    expected_output = "> ERR \"No transaction to rollback\"\n"
    assert extract_relevant_output(output) == expected_output

    capture_io([input: "BEGIN", capture_prompt: false], fn ->
      DesafioCli.loop()
    end)

    output =
      capture_io([input: "ROLLBACK", capture_prompt: false], fn ->
        DesafioCli.loop()
      end)

    expected_output = "> 0\n"

    assert extract_relevant_output(output) == expected_output
  end
end
