defmodule Klix.Builder.TelemetryHandler do
  require Logger

  def handle([_server, :nothing_to_do], _measurements, _metadata, _config) do
    nil
  end

  def handle(event_name, measurements, metadata, _config) do
    Logger.info(event: event_name, measurements: measurements, metadata: metadata)
  end
end
