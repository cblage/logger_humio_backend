defmodule Logger.Backend.Humio.Test do
  use ExUnit.Case, async: false
  require Logger

  @backend {Logger.Backend.Humio, :test}
  Logger.add_backend(@backend)

  setup do
    config(
      ingest_api: Logger.Backend.Humio.IngestApi.Test,
      host: 'humio.url',
      format: "[$level] $message\n",
      token: "<<humio-token>>"
    )

    on_exit(fn ->
      ingest_api().destroy()
    end)

    :ok
  end

  test "default logger level is `:debug`" do
    assert Logger.level() == :debug
  end

  test "does not log when level is under minimum Logger level" do
    config(level: :info)
    Logger.debug("do not log me")
    refute ingest_api().exists()
  end

  test "does log when level is above or equal minimum Logger level" do
    refute ingest_api().exists()
    config(level: :info)
    Logger.warn("you will log me")
    assert ingest_api().exists()
    assert read_log() == "[warn] you will log me\n"
  end

  test "can configure format" do
    config(format: "$message ($level)\n")

    Logger.info("I am formatted")
    assert read_log() == "I am formatted (info)\n"
  end

  test "can configure metadata" do
    config(format: "$metadata$message\n", metadata: [:user_id, :auth])

    Logger.info("hello")
    assert read_log() == "hello\n"

    Logger.metadata(auth: true)
    Logger.metadata(user_id: 11)
    Logger.metadata(user_id: 13)

    Logger.info("hello")
    assert read_log() == "user_id=13 auth=true hello\n"
  end

  test "can handle multi-line messages" do
    config(format: "$metadata$message\n", metadata: [:user_id, :auth])
    Logger.metadata(auth: true)
    Logger.info("hello\n world")
    assert read_log() == "auth=true hello\nauth=true  world\n"
  end

  test "makes sure messages end with a newline" do
    Logger.info("hello")
    assert read_log() == "[info] hello\n"
    Logger.info("hello\n")
    assert read_log() == "[info] hello\n"
  end

  defp config(opts) do
    Logger.configure_backend(@backend, opts)
  end

  defp ingest_api() do
    {:ok, ingest_api} = :gen_event.call(Logger, @backend, :ingest_api)
    ingest_api
  end

  defp read_log() do
    ingest_api().read()
  end
end
