defmodule Klix.Wizard do
  defstruct [:changeset, :current, :data, :steps]

  alias Ecto.Changeset

  defmodule Step do
    @callback changeset(
                parent_changeset :: Changeset.t(),
                params :: Enum.t()
              ) ::
                Changeset.t()
  end

  defmodule Steps.Machine do
  end

  defmodule Steps.LocaleAndIdentity do
  end

  def new(changeset, [step_1 | _] = steps) do
    %__MODULE__{
      changeset: changeset,
      current: step_1,
      data: nil,
      steps: Enum.map(steps, &{&1, &1.changeset(changeset, %{})})
    }
  end

  def next(%__MODULE__{steps: steps, current: current} = wizard, params) do
    wizard = change_step(wizard, params)
    parent_changeset = merge_step(wizard, current)

    case {parent_changeset.valid?, next_step(steps, current)} do
      {true, :complete} ->
        case Changeset.apply_action(parent_changeset, :complete_wizard) do
          {:ok, data} ->
            %{wizard | current: nil, data: data}

          {:error, changeset} ->
            %{wizard | changeset: changeset}
        end

      {true, {new_current, _}} ->
        %{
          wizard
          | changeset: parent_changeset,
            current: new_current
        }

      {false, _} ->
        %{wizard | changeset: parent_changeset}
    end
  end

  def changeset_for_step(wizard, step) do
    Enum.find_value(wizard.steps, fn
      {^step, changeset} -> changeset
      _ -> nil
    end)
  end

  defp change_step(wizard, params) do
    update_in(
      wizard,
      [
        Access.key!(:steps),
        Access.find(fn {step, _} -> step == wizard.current end)
      ],
      fn {step, _} ->
        {step, wizard.current.changeset(wizard.changeset, params)}
      end
    )
  end

  defp merge_step(wizard, current) do
    Changeset.merge(wizard.changeset, changeset_for_step(wizard, current))
  end

  defp next_step([{current, _}, next | _], current), do: next
  defp next_step([_ | rest], current), do: next_step(rest, current)
  defp next_step([], _), do: :complete
end
