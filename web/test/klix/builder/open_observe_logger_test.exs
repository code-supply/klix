defmodule Klix.Builder.OpenObserveLoggerTest do
  use Klix.DataCase, async: true

  alias Klix.Builder.OpenObserveLogger

  setup {Req.Test, :verify_on_exit!}

  @org "default"
  @stream "default"

  test "sends build logs to OpenObserve via HTTP" do
    Req.Test.expect(
      OpenObserveLogger,
      fn conn ->
        assert conn.path_info == ["api", @org, @stream, "_json"]

        assert conn.body_params == %{
                 "_json" => [
                   %{
                     "job" => "builder",
                     "image_id" => 321,
                     "build_id" => 123,
                     "level" => "info",
                     "log" => "here is a log line"
                   }
                 ]
               }

        Req.Test.json(conn, %{
          "code" => 200,
          "status" => [%{"name" => @stream, "successful" => 1, "failed" => 0}]
        })
      end
    )

    OpenObserveLogger.handle(
      [:builder, :build_log],
      %{content: "here is a log line"},
      %{build_id: 123, image_id: 321},
      []
    )
  end

  test "ignores all other events" do
    refute OpenObserveLogger.handle([:builder, :foo], %{}, %{my: :metadata}, [])
  end
end
