defmodule Klix.Builder do
  use GenServer

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts)
  end

  @impl true
  def init(opts) do
    state = %{clock: Keyword.fetch!(opts, :clock)}
    send(state.clock, :clock_read)
    {:ok, state}
  end

  @impl true
  def handle_info({:clock_time, _datetime}, state) do
    build = Klix.Images.next_build()
    :telemetry.execute([:builder, :start], %{image_id: build.image_id}, %{})
    {:noreply, state}
  end
end
