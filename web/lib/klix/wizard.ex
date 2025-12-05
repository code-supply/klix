defmodule Klix.Wizard do
  defstruct [:changeset, :changeset_for_step, :current, :data, :steps]

  alias Ecto.Changeset

  defmodule Step do
    @callback title :: String.t()
    @callback struct :: struct()
    @callback cast(struct(), params :: Enum.t()) :: Changeset.t()
    @callback validate(Changeset.t()) :: Changeset.t()
  end

  def new([step_1 | _] = steps) do
    wizard = %__MODULE__{
      changeset: nil,
      current: step_1,
      data: nil,
      steps: Enum.map(steps, &{&1, step_changeset(&1, %{})})
    }

    %{wizard | changeset_for_step: changeset_for_step(wizard, step_1)}
  end

  def complete?(wizard), do: !!wizard.data

  def next(%__MODULE__{steps: steps, current: current} = wizard, params) do
    {step_changeset, wizard} = change_step(wizard, params)

    case {Changeset.apply_action(step_changeset, :next), next_step(steps, current)} do
      {{:ok, _data}, :complete} ->
        complete(wizard)

      {{:ok, _data}, {new_current, _}} ->
        %{
          wizard
          | changeset_for_step: changeset_for_step(wizard, new_current),
            current: new_current
        }

      {{:error, changeset}, _} ->
        %{wizard | changeset_for_step: changeset}
    end
  end

  def previous(%__MODULE__{steps: steps, current: current} = wizard) do
    case previous_step(steps, current) do
      :complete ->
        wizard

      {new_current, _} ->
        %{
          wizard
          | changeset_for_step: changeset_for_step(wizard, new_current),
            current: new_current
        }
    end
  end

  def changeset_for_step(wizard, step) do
    Enum.find_value(wizard.steps, fn
      {^step, changeset} -> changeset
      _ -> nil
    end)
  end

  defp complete(wizard) do
    wizard = %{
      wizard
      | changeset:
          wizard.steps
          |> Enum.map(fn {_, cs} -> cs end)
          |> Enum.reduce(fn step_changeset, cs ->
            Changeset.merge(cs, step_changeset)
          end)
    }

    case Changeset.apply_action(wizard.changeset, :complete_wizard) do
      {:ok, data} ->
        %{wizard | current: nil, data: data}

      {:error, changeset} ->
        dbg(changeset.changes)
        %{wizard | changeset: changeset}
    end
  end

  defp change_step(wizard, params) do
    step_changeset = step_changeset(wizard.current, params)

    {
      step_changeset,
      update_in(
        wizard,
        [
          Access.key!(:steps),
          Access.find(fn {step, _} -> step == wizard.current end)
        ],
        fn {step, _} ->
          {step, step_changeset}
        end
      )
    }
  end

  defp step_changeset(step, params) do
    step.struct()
    |> step.cast(params)
    |> step.validate()
  end

  defp next_step([{current, _}, next | _], current), do: next
  defp next_step([_ | rest], current), do: next_step(rest, current)
  defp next_step([], _), do: :complete

  defp previous_step(steps, current),
    do:
      steps
      |> Enum.reverse()
      |> next_step(current)
end
