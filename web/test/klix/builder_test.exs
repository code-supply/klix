defmodule Klix.BuilderTest do
  use Klix.DataCase, async: true

  describe "when a build is found" do
    test "emits an event" do
      {:ok, %{id: id}} = Klix.Factory.params(:image) |> Klix.Images.create()

      ref = start_builder()

      assert_receive {[:builder, :build_found], ^ref, %{image_id: ^id}, _meta}
    end
  end

  describe "when there's nothing to do" do
    test "emits an event" do
      ref = start_builder()
      assert_receive {[:builder, :no_builds], ^ref, _empty_measurements, _meta}
    end
  end

  defp subscribe do
    :telemetry_test.attach_event_handlers(self(), [
      [:builder, :build_found],
      [:builder, :idle],
      [:builder, :no_builds]
    ])
  end

  defp start_builder do
    ref = subscribe()
    builder = start_link_supervised!({Klix.Builder, scheduler: self()})
    assert_receive {[:builder, :idle], ^ref, _empty_measurements, _meta}
    Ecto.Adapters.SQL.Sandbox.allow(Klix.Repo, self(), builder)
    send(builder, :run)
    ref
  end
end
