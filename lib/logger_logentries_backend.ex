defmodule Logger.Backend.Logentries do
  use GenEvent

  @default_format "[$level] $message\n"

  def init({__MODULE__, name}) do
    {:ok, configure(name, [])}
  end

  def handle_call({:configure, opts}, %{name: name}) do
    {:ok, :ok, configure(name, opts)}
  end

  def handle_call(:connector, %{connector: connector} = state) do
    {:ok, {:ok, connector}, state}
  end

  def handle_event({level, _gl, {Logger, msg, ts, md}}, %{level: min_level} = state) do
    if is_nil(min_level) or Logger.compare_levels(level, min_level) != :lt do
      log_event(level, msg, ts, md, state)
    end
    {:ok, state}
  end

  defp log_event(level, msg, ts, md, %{connector: connector, host: host, port: port, token: token} = state) do
    msg
    |> format_message(level, ts, md, state)
    |> add_token_to_lines(token)
    |> transmit(connector, host, port)
  end

  defp format_message(msg, level, ts, md, state) do
    msg
    |> IO.chardata_to_string
    |> String.split("\n")
    |> filter_empty_strings
    |> Enum.map(&(format_event(level, &1, ts, md, state)))
    |> Enum.join("")
  end

  defp format_event(level, msg, ts, md, %{format: format, metadata: keys}) do
    Logger.Formatter.format(format, level, msg, ts, take_metadata(md, keys))
  end

  defp add_token_to_lines(entry, token) do
    entry
    |> IO.chardata_to_string
    |> String.split("\n")
    |> filter_empty_strings
    |> Enum.map(&(" #{token} #{&1}"))
    |> Enum.join("\n")
    |> add_optional_newline
  end

  defp filter_empty_strings(strings) do
    strings
    |> Enum.filter(&(String.strip(&1) != ""))
  end

  defp add_optional_newline(<<_::utf8, "\n">>=entry) do
    entry
  end
  defp add_optional_newline(entry) do
    entry <> "\n"
  end

  defp transmit(entry, connector, host, port) do
    connector.transmit(host, port, entry)
  end

  defp take_metadata(metadata, keys) do
    Enum.reduce(keys, [], fn key, acc ->
      case Keyword.fetch(metadata, key) do
        {:ok, val} -> [{key, val} | acc]
        :error     -> acc
      end
    end) |> Enum.reverse()
  end

  defp configure(name, opts) do
    env = Application.get_env(:logger, name, [])
    opts = Keyword.merge(env, opts)
    Application.put_env(:logger, name, opts)

    connector = Keyword.get(opts, :connector, Logger.Backend.Logentries.Output.Tcp)
    host = Keyword.get(opts, :host, 'data.logentries.com')
    port = Keyword.get(opts, :port, 80)
    level = Keyword.get(opts, :level, :debug)
    metadata = Keyword.get(opts, :metadata, [])
    format = Keyword.get(opts, :format, @default_format) |> Logger.Formatter.compile
    token = Keyword.get(opts, :token, "")

    %{
      name: name,
      connector: connector,
      host: host,
      port: port,
      level: level,
      format: format,
      metadata: metadata,
      token: token
    }
  end
end
