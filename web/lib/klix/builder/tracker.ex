defmodule Klix.Builder.Tracker do
  use GenServer

  require Logger

  defmodule Job.Progress do
    defstruct done: 0, expected: 0, running: 0, failed: 0

    def from_fields([done, expected, running, failed]) do
      %__MODULE__{
        done: done,
        expected: expected,
        running: running,
        failed: failed
      }
    end
  end

  defmodule Job.FileTransfer do
    defstruct [:num]
  end

  defmodule Job do
    defstruct [:state, :text, progress: %Job.Progress{}, activities: []]
  end

  def start_link(opts) do
    {name, opts} = Keyword.pop(opts, :name)
    GenServer.start_link(__MODULE__, opts, name: name)
  end

  def handle(_event_name, %{content: content}, _metadata, config) do
    GenServer.cast(config[:tracker], {:parse, content})
    config[:tracker]
  end

  def jobs(tracker \\ __MODULE__), do: GenServer.call(tracker, :jobs)
  def messages(tracker \\ __MODULE__), do: GenServer.call(tracker, :messages)

  @impl true
  def init(_init_arg) do
    {:ok, %{jobs: %{}, messages: []}}
  end

  @impl true
  def handle_cast({:parse, nix_output}, state) do
    {
      :noreply,
      nix_output
      |> String.split("@nix ", trim: true)
      |> Enum.map(&JSON.decode/1)
      |> Enum.reduce(state, &handle_decoded/2)
    }
  end

  @impl true
  def handle_call(:jobs, _from, state) do
    {:reply, state.jobs, state}
  end

  @impl true
  def handle_call(:messages, _from, state) do
    {:reply, Enum.reverse(state.messages), state}
  end

  defp handle_decoded({:ok, %{"id" => id, "action" => "start"} = doc}, state) do
    update_in(state.jobs, &Map.put(&1, id, %Job{state: :started, text: doc["text"]}))
  end

  defp handle_decoded({:ok, %{"id" => id, "action" => "stop"}}, state) do
    update_in(
      state,
      [Access.key!(:jobs), Access.key!(id)],
      &%{&1 | state: :stopped}
    )
  end

  defp handle_decoded(
         {
           :ok,
           %{
             "id" => id,
             "action" => "result",
             "fields" => fields,
             "type" => 105
           }
         },
         state
       ) do
    put_in(
      state,
      [:jobs, Access.key!(id), Access.key!(:progress)],
      Job.Progress.from_fields(fields)
    )
  end

  defp handle_decoded(
         {
           :ok,
           %{
             "id" => id,
             "action" => "result",
             "fields" => [101, num],
             "type" => 106
           }
         },
         state
       ) do
    update_in(state, [:jobs, Access.key!(id), Access.key!(:activities)], fn activities ->
      activities ++ [%Job.FileTransfer{num: num}]
    end)
  end

  defp handle_decoded({:ok, %{"action" => "msg", "level" => level, "msg" => msg}}, state) do
    update_in(state.messages, &[%{level: level, msg: msg} | &1])
  end

  defp handle_decoded({:ok, _event}, state), do: state
  defp handle_decoded({:error, _term}, state), do: state
end
