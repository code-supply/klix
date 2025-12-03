defmodule Klix.Wizard do
  defstruct [:changeset, :changeset_for_step, :current, :data, :steps]

  alias Ecto.Changeset

  defmodule Step do
    @callback changeset(params :: Enum.t()) :: Changeset.t()
  end

  defmodule Steps.Machine do
    @behaviour Step

    def changeset(params) do
      %Klix.Images.Image{}
      |> Ecto.Changeset.cast(params, [:machine])
      |> Ecto.Changeset.validate_required([:machine])
    end
  end

  defmodule Steps.LocaleAndIdentity do
    @behaviour Step

    def changeset(params) do
      %Klix.Images.Image{}
      |> Ecto.Changeset.cast(params, [:hostname, :timezone])
    end
  end

  def sign_up_steps do
    [Steps.Machine, Steps.LocaleAndIdentity]
  end

  def new(struct, [step_1 | _] = steps) do
    wizard = %__MODULE__{
      changeset: Ecto.Changeset.change(struct),
      current: step_1,
      data: nil,
      steps: Enum.map(steps, &{&1, &1.changeset(%{})})
    }

    %{wizard | changeset_for_step: changeset_for_step(wizard, step_1)}
  end

  def next(%__MODULE__{steps: steps, current: current} = wizard, params) do
    {step_changeset, wizard} = change_step(wizard, params)
    parent_changeset = merge_step(wizard, current)

    case {Changeset.apply_action(step_changeset, :next), next_step(steps, current)} do
      {{:ok, _data}, :complete} ->
        case Changeset.apply_action(parent_changeset, :complete_wizard) do
          {:ok, data} ->
            %{wizard | current: nil, data: data}

          {:error, changeset} ->
            %{wizard | changeset: changeset}
        end

      {{:ok, _data}, {new_current, _}} ->
        %{
          wizard
          | changeset: parent_changeset,
            changeset_for_step: changeset_for_step(wizard, new_current),
            current: new_current
        }

      {{:error, changeset}, _} ->
        %{wizard | changeset: parent_changeset, changeset_for_step: changeset}
    end
  end

  def changeset_for_step(wizard, step) do
    Enum.find_value(wizard.steps, fn
      {^step, changeset} -> changeset
      _ -> nil
    end)
  end

  defp change_step(wizard, params) do
    step_changeset = wizard.current.changeset(params)

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

  defp merge_step(wizard, current) do
    Changeset.merge(wizard.changeset, changeset_for_step(wizard, current))
  end

  defp next_step([{current, _}, next | _], current), do: next
  defp next_step([_ | rest], current), do: next_step(rest, current)
  defp next_step([], _), do: :complete
end
