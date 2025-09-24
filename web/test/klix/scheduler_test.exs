defmodule Klix.SchedulerTest do
  use Klix.DataCase, async: true

  test "when server is idle, tell it to set up" do
    Klix.Scheduler.handle([:some_server, :idle], %{}, %{pid: self()}, [])
    assert_receive :set_up
  end

  test "if server has nothing to do, sleep before setting up again" do
    sleep_time = 100

    Klix.Scheduler.handle([:some_server, :nothing_to_do], %{}, %{pid: self()},
      sleep_time: sleep_time
    )

    refute_received :set_up
    Process.sleep(sleep_time)
    assert_receive :set_up
  end

  test "if setup completes with work to do, tell it to run" do
    Klix.Scheduler.handle([:some_server, :setup_complete], %{}, %{pid: self()}, [])
    assert_receive :run
  end

  test "when server completes its work, tell it to set up again" do
    Klix.Scheduler.handle([:some_server, :run_complete], %{}, %{pid: self()}, [])
    assert_receive :set_up
  end

  test "can return a list of scheduler event names for a given server" do
    assert Klix.Scheduler.events_for(:builder) == [
             [:builder, :idle],
             [:builder, :nothing_to_do],
             [:builder, :setup_complete],
             [:builder, :run_complete],
             [:builder, :run_failure]
           ]
  end
end
