defmodule Logger.Backend.Humio.Client.Test do
  @moduledoc """
  Test client for the backend.  Writes the body to @logfile and provides convenience methods for writing back logged lines and cleaning up the created file.
  """
  @behaviour Logger.Backend.Humio.Client

  @logfile "test_log.log"

  @impl true
  def send(%{base_url: _base_url, path: _path, body: body, headers: _headers} = params) do
    File.write!(@logfile, body)
    {:ok, params}
  end

  def read() do
    if exists() do
      File.read!(@logfile)
    end
  end

  def exists() do
    File.exists?(@logfile)
  end

  def destroy() do
    if exists() do
      File.rm!(@logfile)
    end
  end
end
