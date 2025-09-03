defmodule Klix.Builder.TelemetryHandlerTest do
  use Klix.DataCase, async: false

  import ExUnit.CaptureLog

  setup do
    initial_level = Logger.get_module_level(Klix.Builder.TelemetryHandler)
    Logger.put_module_level(Klix.Builder.TelemetryHandler, :info)

    on_exit(fn ->
      Logger.put_module_level(Klix.Builder.TelemetryHandler, initial_level)
    end)
  end

  test "logs events" do
    for event <- Klix.Builder.telemetry_events() do
      log =
        capture_log(fn ->
          Klix.Builder.TelemetryHandler.handle(event, %{}, %{my: :metadata}, [])
        end)

      assert log =~ inspect(event)
    end
  end
end
