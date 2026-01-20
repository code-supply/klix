defmodule Klix.Builder.OpenObserveLogger do
  def handle([:builder, :build_log], measurements, metadata, _config) do
    Req.new(
      [
        method: :get,
        url: "http://localhost:5080/api/default/default/_json",
        json: [
          %{
            "level" => "info",
            "job" => "builder",
            "log" => measurements.content
          }
          |> Map.merge(metadata)
        ]
      ]
      |> Keyword.merge(Application.fetch_env!(:klix, :open_observe_logger))
    )
    |> Req.post!()
  end

  def handle(_event, _measurements, _metadata, _config), do: nil
end
