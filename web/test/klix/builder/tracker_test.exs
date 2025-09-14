defmodule Klix.Builder.TrackerTest do
  use Klix.DataCase, async: true

  alias Klix.Builder.Tracker

  test "exposes package jobs starting and stopping" do
    tracker = start_link_supervised!(Tracker)

    handle(tracker, %{"action" => "start", "id" => 1, "text" => "original"})
    assert %{1 => %{state: :started}} = Tracker.jobs(tracker)

    handle(tracker, %{"action" => "start", "id" => 2, "text" => ""})

    assert %{
             1 => %Tracker.Job{state: :started},
             2 => %Tracker.Job{state: :started}
           } = Tracker.jobs(tracker)

    handle(tracker, %{"action" => "stop", "id" => 1})

    assert %{
             1 => %Tracker.Job{state: :stopped, text: "original"},
             2 => %Tracker.Job{state: :started}
           } = Tracker.jobs(tracker)
  end

  test "records progress against job IDs" do
    assert %{
             1 => %Tracker.Job{
               state: :started,
               progress: %Tracker.Job.Progress{
                 done: 4,
                 expected: 2,
                 running: 3,
                 failed: 4
               }
             }
           } =
             start_link_supervised!(Tracker)
             |> handle(%{"action" => "start", "id" => 1})
             |> handle(%{
               "action" => "result",
               "fields" => [1, 2, 3, 4],
               "id" => 1,
               "type" => 105
             })
             |> handle(%{
               "action" => "result",
               "fields" => [4, 2, 3, 4],
               "id" => 1,
               "type" => 105
             })
             |> Tracker.jobs()
  end

  test "records file transfers against job IDs" do
    assert %{
             1 => %Tracker.Job{
               text: "copying something",
               state: :started,
               activities: [
                 %Tracker.Job.FileTransfer{num: 0}
               ]
             }
           } =
             start_link_supervised!(Tracker)
             |> handle(%{"action" => "start", "id" => 1, "text" => "copying something"})
             |> handle(%{
               "action" => "result",
               "fields" => [101, 0],
               "id" => 1,
               "type" => 106
             })
             |> Tracker.jobs()
  end

  test "ignores other successful JSON parses" do
    assert %{
             1 => %Tracker.Job{state: :started}
           } =
             start_link_supervised!(Tracker)
             |> handle(%{"action" => "start", "id" => 1})
             |> handle(%{
               "action" => "result",
               "fields" => [100, 0],
               "id" => 1,
               # store optimisation
               "type" => 106
             })
             |> Tracker.jobs()
  end

  test "records messages" do
    tracker = start_link_supervised!(Tracker)

    handle(tracker, %{"action" => "msg", "level" => 4, "msg" => "something everyone should know"})
    assert [%{level: 4, msg: "something everyone should know"}] = Tracker.messages(tracker)
  end

  test "can handle multiple @nix lines in one go" do
    tracker = start_link_supervised!(Tracker)

    doc1 = %{"action" => "start", "id" => 1, "text" => ""}
    doc2 = %{"action" => "start", "id" => 2, "text" => ""}

    Tracker.handle(
      [:builder, :build_log],
      %{content: ~s(@nix #{JSON.encode!(doc1)}\n@nix #{JSON.encode!(doc2)})},
      %{},
      tracker: tracker
    )

    assert %{
             1 => %Tracker.Job{state: :started},
             2 => %Tracker.Job{state: :started}
           } = Tracker.jobs(tracker)
  end

  defp handle(tracker, doc) do
    Tracker.handle(
      [:builder, :build_log],
      %{content: ~s(@nix #{JSON.encode!(doc)})},
      %{},
      tracker: tracker
    )
  end
end
