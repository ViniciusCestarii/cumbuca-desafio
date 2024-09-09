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

  defp strip_ansi_colors(string) do
    String.replace(string, ~r/\e\[\d+m/, "")
  end

  defp extract_relevant_output(output) do
    case String.split(output, "> End of input detected. Exiting...", parts: 2) do
      [relevant_output | _] -> strip_ansi_colors(relevant_output)
      _ -> strip_ansi_colors(output)
    end
  end


  # Test from https://github.com/appcumbuca/desafios/blob/master/desafio-back-end-pleno.md examples

  test "command output" do
    assert capture_io(fn -> DesafioCli.loop() end) =~ ">"
  end >
    TRY

  test(
    "Caso se tente invocar um comando que não seja um dos abaixo, deve ser emitido um erro apropriadamente"
  ) do
    output = capture_io([input: "TRY", capture_prompt: false], fn -> DesafioCli.loop() end)
    assert extract_relevant_output(output) == "> ERR \"No command TRY\"\n"
  end

  test "um comando seja chamado com sintaxe incorreta, deve também ser emitido um erro" do
    output =
      capture_io([input: "SET x", capture_prompt: false], fn ->
        DesafioCli.loop()
      end)

    expected_output = "> ERR \"SET <chave> <valor> - Syntax error\"\n"
    assert extract_relevant_output(output) == expected_output
  end

  # O comando SET deve definir o valor de uma chave. Caso a chave não exista, ela deve ser criada. Caso a chave já existe, ela será sobreescrita. O comando deve retornar se a chave já existia e o novo valor dela.

  test "SET" do
    output =
      capture_io([input: "SET teste 1", capture_prompt: false], fn ->
        DesafioCli.loop()
      end)

    expected_output = "> FALSE 1\n"
    assert extract_relevant_output(output) == expected_output

    output =
      capture_io([input: "SET teste 2", capture_prompt: false], fn ->
        DesafioCli.loop()
      end)

    expected_output = "> TRUE 2\n"
    assert extract_relevant_output(output) == expected_output
  end

  # O comando GET deve recuperar o valor de uma chave. Caso a chave não exista, deve ser retornado o valor NIL. Caso a chave exista, deve ser retornado o valor armazenado nela.

  test "GET" do
    output =
      capture_io([input: "GET teste", capture_prompt: false], fn ->
        DesafioCli.loop()
      end)

    expected_output = "> NIL\n"
    assert extract_relevant_output(output) == expected_output

    output =
      capture_io([input: "SET teste 1", capture_prompt: false], fn ->
        DesafioCli.loop()
      end)

    expected_output = "> FALSE 1\n"
    assert extract_relevant_output(output) == expected_output

    output =
      capture_io([input: "GET teste", capture_prompt: false], fn ->
        DesafioCli.loop()
      end)

    expected_output = "> 1\n"
    assert extract_relevant_output(output) == expected_output
  end

  # O comando BEGIN deve iniciar uma transação. Ele deve retornar o atual nível de transação - i.e. quantas transações abertas existem. O banco se inicia no nível de transação 0.

  test "BEGIN" do
    output =
      capture_io([input: "BEGIN", capture_prompt: false], fn ->
        DesafioCli.loop()
      end)

    expected_output = "> 1\n"
    assert extract_relevant_output(output) == expected_output

    output =
      capture_io([input: "SET teste 1", capture_prompt: false], fn ->
        DesafioCli.loop()
      end)

    expected_output = "> FALSE 1\n"

    assert extract_relevant_output(output) == expected_output

    output =
      capture_io([input: "GET teste", capture_prompt: false], fn ->
        DesafioCli.loop()
      end)

    expected_output = "> 1\n"

    assert extract_relevant_output(output) == expected_output
  end

  test "BEGIN recursive transaction" do
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

  # O comando ROLLBACK deve encerrar uma transação sem aplicar suas alterações. Isto é, todas as alterações criadas na transação atual devem ser descartadas. Deve retornar o nível de transação após o rollback.

  test "ROLLBACK" do
    output =
      capture_io([input: "GET teste", capture_prompt: false], fn -> DesafioCli.loop() end)

    expected_output = "> NIL\n"
    assert extract_relevant_output(output) == expected_output

    output =
      capture_io([input: "BEGIN", capture_prompt: false], fn -> DesafioCli.loop() end)

    expected_output = "> 1\n"
    assert extract_relevant_output(output) == expected_output

    output =
      capture_io([input: "SET teste 1", capture_prompt: false], fn -> DesafioCli.loop() end)

    expected_output = "> FALSE 1\n"
    assert extract_relevant_output(output) == expected_output

    output =
      capture_io([input: "GET teste", capture_prompt: false], fn -> DesafioCli.loop() end)

    expected_output = "> 1\n"
    assert extract_relevant_output(output) == expected_output

    output =
      capture_io([input: "ROLLBACK", capture_prompt: false], fn -> DesafioCli.loop() end)

    expected_output = "> 0\n"
    assert extract_relevant_output(output) == expected_output

    output =
      capture_io([input: "GET teste", capture_prompt: false], fn -> DesafioCli.loop() end)

    expected_output = "> NIL\n"
    assert extract_relevant_output(output) == expected_output
  end

  test "ROLLBACK recursive transactions" do
    output =
      capture_io([input: "GET teste", capture_prompt: false], fn -> DesafioCli.loop() end)

    expected_output = "> NIL\n"
    assert extract_relevant_output(output) == expected_output

    output =
      capture_io([input: "BEGIN", capture_prompt: false], fn -> DesafioCli.loop() end)

    expected_output = "> 1\n"
    assert extract_relevant_output(output) == expected_output

    output =
      capture_io([input: "SET teste 1", capture_prompt: false], fn -> DesafioCli.loop() end)

    expected_output = "> FALSE 1\n"
    assert extract_relevant_output(output) == expected_output

    output =
      capture_io([input: "GET teste", capture_prompt: false], fn -> DesafioCli.loop() end)

    expected_output = "> 1\n"
    assert extract_relevant_output(output) == expected_output

    output =
      capture_io([input: "BEGIN", capture_prompt: false], fn -> DesafioCli.loop() end)

    expected_output = "> 2\n"
    assert extract_relevant_output(output) == expected_output

    output =
      capture_io([input: "SET foo bar", capture_prompt: false], fn -> DesafioCli.loop() end)

    expected_output = "> FALSE bar\n"
    assert extract_relevant_output(output) == expected_output

    output =
      capture_io([input: "SET bar baz", capture_prompt: false], fn -> DesafioCli.loop() end)

    expected_output = "> FALSE baz\n"
    assert extract_relevant_output(output) == expected_output

    output =
      capture_io([input: "GET foo", capture_prompt: false], fn -> DesafioCli.loop() end)

    expected_output = "> bar\n"
    assert extract_relevant_output(output) == expected_output

    output =
      capture_io([input: "GET bar", capture_prompt: false], fn -> DesafioCli.loop() end)

    expected_output = "> baz\n"
    assert extract_relevant_output(output) == expected_output

    output =
      capture_io([input: "ROLLBACK", capture_prompt: false], fn -> DesafioCli.loop() end)

    expected_output = "> 1\n"
    assert extract_relevant_output(output) == expected_output

    output =
      capture_io([input: "GET foo", capture_prompt: false], fn -> DesafioCli.loop() end)

    expected_output = "> NIL\n"

    assert extract_relevant_output(output) == expected_output

    output =
      capture_io([input: "GET bar", capture_prompt: false], fn -> DesafioCli.loop() end)

    expected_output = "> NIL\n"

    assert extract_relevant_output(output) == expected_output

    output =
      capture_io([input: "GET teste", capture_prompt: false], fn -> DesafioCli.loop() end)

    expected_output = "> 1\n"

    assert extract_relevant_output(output) == expected_output
  end

  # O comando COMMIT deve encerrar a transação atual aplicando todas as suas alterações. Isto é, as alterações da transação atual devem ser
  # inclusas nas alterações da transação inferior, ou, caso após o COMMIT estejamos no nível de transação 0, as transações devem ser efetivadas no
  # banco. O comando COMMIT deve retornar o nível de transação após o commit.

  test "COMMIT" do
    output =
      capture_io([input: "GET teste", capture_prompt: false], fn -> DesafioCli.loop() end)

    expected_output = "> NIL\n"
    assert extract_relevant_output(output) == expected_output

    output =
      capture_io([input: "BEGIN", capture_prompt: false], fn -> DesafioCli.loop() end)

    expected_output = "> 1\n"
    assert extract_relevant_output(output) == expected_output

    output =
      capture_io([input: "SET teste 1", capture_prompt: false], fn -> DesafioCli.loop() end)

    expected_output = "> FALSE 1\n"
    assert extract_relevant_output(output) == expected_output

    output =
      capture_io([input: "GET teste", capture_prompt: false], fn -> DesafioCli.loop() end)

    expected_output = "> 1\n"
    assert extract_relevant_output(output) == expected_output

    output =
      capture_io([input: "COMMIT", capture_prompt: false], fn -> DesafioCli.loop() end)

    expected_output = "> 0\n"
    assert extract_relevant_output(output) == expected_output

    output =
      capture_io([input: "GET teste", capture_prompt: false], fn -> DesafioCli.loop() end)

    expected_output = "> 1\n"
    assert extract_relevant_output(output) == expected_output
  end

  test "COMMIT recursive transactions" do
    output =
      capture_io([input: "GET teste", capture_prompt: false], fn -> DesafioCli.loop() end)

    expected_output = "> NIL\n"
    assert extract_relevant_output(output) == expected_output

    output =
      capture_io([input: "BEGIN", capture_prompt: false], fn -> DesafioCli.loop() end)

    expected_output = "> 1\n"
    assert extract_relevant_output(output) == expected_output

    output =
      capture_io([input: "SET teste 1", capture_prompt: false], fn -> DesafioCli.loop() end)

    expected_output = "> FALSE 1\n"
    assert extract_relevant_output(output) == expected_output

    output =
      capture_io([input: "GET teste", capture_prompt: false], fn -> DesafioCli.loop() end)

    expected_output = "> 1\n"
    assert extract_relevant_output(output) == expected_output

    output =
      capture_io([input: "BEGIN", capture_prompt: false], fn -> DesafioCli.loop() end)

    expected_output = "> 2\n"
    assert extract_relevant_output(output) == expected_output

    output =
      capture_io([input: "SET foo bar", capture_prompt: false], fn -> DesafioCli.loop() end)

    expected_output = "> FALSE bar\n"
    assert extract_relevant_output(output) == expected_output

    output =
      capture_io([input: "SET bar baz", capture_prompt: false], fn -> DesafioCli.loop() end)

    expected_output = "> FALSE baz\n"
    assert extract_relevant_output(output) == expected_output

    output =
      capture_io([input: "GET foo", capture_prompt: false], fn -> DesafioCli.loop() end)

    expected_output = "> bar\n"
    assert extract_relevant_output(output) == expected_output

    output =
      capture_io([input: "GET bar", capture_prompt: false], fn -> DesafioCli.loop() end)

    expected_output = "> baz\n"
    assert extract_relevant_output(output) == expected_output

    output =
      capture_io([input: "COMMIT", capture_prompt: false], fn -> DesafioCli.loop() end)

    expected_output = "> 1\n"
    assert extract_relevant_output(output) == expected_output

    output =
      capture_io([input: "GET foo", capture_prompt: false], fn -> DesafioCli.loop() end)

    expected_output = "> bar\n"
    assert extract_relevant_output(output) == expected_output

    output =
      capture_io([input: "GET bar", capture_prompt: false], fn -> DesafioCli.loop() end)

    expected_output = "> baz\n"

    assert extract_relevant_output(output) == expected_output

    output =
      capture_io([input: "GET teste", capture_prompt: false], fn -> DesafioCli.loop() end)

    expected_output = "> 1\n"

    assert extract_relevant_output(output) == expected_output

    output =
      capture_io([input: "ROLLBACK", capture_prompt: false], fn -> DesafioCli.loop() end)

    expected_output = "> 0\n"

    assert extract_relevant_output(output) == expected_output

    output =
      capture_io([input: "GET teste", capture_prompt: false], fn -> DesafioCli.loop() end)

    expected_output = "> NIL\n"

    assert extract_relevant_output(output) == expected_output

    output =
      capture_io([input: "GET foo", capture_prompt: false], fn -> DesafioCli.loop() end)

    expected_output = "> NIL\n"

    assert extract_relevant_output(output) == expected_output

    output =
      capture_io([input: "GET bar", capture_prompt: false], fn -> DesafioCli.loop() end)

    expected_output = "> NIL\n"

    assert extract_relevant_output(output) == expected_output
  end

  # Por exemplo, abcd, a10, "uma string com espaços", "\"teste\"" "101" e "TRUE" são todas strings, com os valores abcd, a10, uma string com espaços, "teste", 101 e TRUE respectivamente.

  test "SET string" do
    output =
      capture_io([input: "SET teste abcd", capture_prompt: false], fn ->
        DesafioCli.loop()
      end)

    expected_output = "> FALSE abcd\n"

    assert extract_relevant_output(output) == expected_output

    output =
      capture_io([input: "GET teste", capture_prompt: false], fn ->
        DesafioCli.loop()
      end)

    expected_output = "> abcd\n"

    assert extract_relevant_output(output) == expected_output

    output =
      capture_io([input: "SET teste a10", capture_prompt: false], fn ->
        DesafioCli.loop()
      end)

    expected_output = "> TRUE a10\n"

    assert extract_relevant_output(output) == expected_output

    output =
      capture_io([input: "GET teste", capture_prompt: false], fn ->
        DesafioCli.loop()
      end)

    expected_output = "> a10\n"

    assert extract_relevant_output(output) == expected_output

    output =
      capture_io([input: "SET teste \"uma string com espaços\"", capture_prompt: false], fn ->
        DesafioCli.loop()
      end)

    expected_output = "> TRUE uma string com espaços\n"
    assert extract_relevant_output(output) == expected_output

    output =
      capture_io([input: "GET teste", capture_prompt: false], fn ->
        DesafioCli.loop()
      end)

    expected_output = "> uma string com espaços\n"

    assert extract_relevant_output(output) == expected_output

    output =
      capture_io([input: "SET teste \"\"teste\"\"", capture_prompt: false], fn ->
        DesafioCli.loop()
      end)

    expected_output = "> TRUE \"teste\"\n"

    assert extract_relevant_output(output) == expected_output

    output =
      capture_io([input: "GET teste", capture_prompt: false], fn ->
        DesafioCli.loop()
      end)

    expected_output = "> \"teste\"\n"

    assert extract_relevant_output(output) == expected_output

    output =
      capture_io([input: "SET teste \"101\"", capture_prompt: false], fn ->
        DesafioCli.loop()
      end)

    expected_output = "> TRUE 101\n"

    assert extract_relevant_output(output) == expected_output

    output =
      capture_io([input: "GET teste", capture_prompt: false], fn ->
        DesafioCli.loop()
      end)

    expected_output = "> 101\n"

    assert extract_relevant_output(output) == expected_output

    output =
      capture_io([input: "SET teste \"TRUE\"", capture_prompt: false], fn ->
        DesafioCli.loop()
      end)

    expected_output = "> TRUE TRUE\n"

    assert extract_relevant_output(output) == expected_output
  end

  # NIL não pode ser inserido.

  test "SET NIL" do
    output =
      capture_io([input: "SET teste NIL", capture_prompt: false], fn ->
        DesafioCli.loop()
      end)

    expected_output = "> ERR \"NIL is not a valid value - Syntax error\"\n"

    assert extract_relevant_output(output) == expected_output

    output =
      capture_io([input: "GET teste", capture_prompt: false], fn ->
        DesafioCli.loop()
      end)

    expected_output = "> NIL\n"

    assert extract_relevant_output(output) == expected_output

    # NIL as a string can be inserted
    output =
      capture_io([input: "SET teste \"NIL\"", capture_prompt: false], fn ->
        DesafioCli.loop()
      end)

    expected_output = "> FALSE NIL\n"

    assert extract_relevant_output(output) == expected_output

    output =
      capture_io([input: "GET teste", capture_prompt: false], fn ->
        DesafioCli.loop()
      end)

    expected_output = "> NIL\n"

    assert extract_relevant_output(output) == expected_output
  end
end
