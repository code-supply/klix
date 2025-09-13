defmodule Klix.Builder.LoggerTest do
  use Klix.DataCase, async: false

  import ExUnit.CaptureLog

  setup do
    initial_level = Logger.get_module_level(Klix.Builder.Logger)
    Logger.put_module_level(Klix.Builder.Logger, :info)

    on_exit(fn ->
      Logger.put_module_level(Klix.Builder.Logger, initial_level)
    end)
  end

  test "logs events" do
    Klix.Builder.telemetry_events()
    |> Enum.each(fn
      [:builder, :nothing_to_do] = event ->
        log =
          capture_log(fn ->
            Klix.Builder.Logger.handle(event, %{}, %{my: :metadata}, [])
          end)

        assert log == ""

      event ->
        log =
          capture_log(fn ->
            Klix.Builder.Logger.handle(event, %{}, %{my: :metadata}, [])
          end)

        assert log =~ inspect(event)
    end)
  end
end
