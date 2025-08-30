defmodule Klix.BuilderTest do
  use Klix.DataCase, async: true

  test "emits an event on start" do
    ref = :telemetry_test.attach_event_handlers(self(), [[:builder, :start]])

    {:ok, %{id: id}} = Klix.Factory.params(:image) |> Klix.Images.create()

    start_builder()

    assert_receive {[:builder, :start], ^ref, %{image_id: ^id}, _meta}
  end

  defp start_builder do
    builder = start_link_supervised!({Klix.Builder, clock: self()})
    assert_receive :clock_read
    Ecto.Adapters.SQL.Sandbox.allow(Klix.Repo, self(), builder)
    send(builder, {:clock_time, ~U[2000-01-01 00:00:00Z]})
    builder
  end
end
