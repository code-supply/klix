defmodule Klix.Scheduler do
  def events_for(server) do
    for event <- [:idle, :nothing_to_do, :setup_complete, :run_complete, :run_failure] do
      [server, event]
    end
  end

  def handle([_name, :idle], _measurements, %{pid: server}, _config) do
    Process.send(server, :set_up, [])
  end

  def handle([_name, :nothing_to_do], _measurements, %{pid: server}, config) do
    Process.send_after(server, :set_up, config[:sleep_time])
  end

  def handle([_name, :setup_complete], _measurements, %{pid: server}, _config) do
    Process.send(server, :run, [])
  end

  def handle([_name, :run_complete], _measurements, %{pid: server}, _config) do
    Process.send(server, :set_up, [])
  end
end
