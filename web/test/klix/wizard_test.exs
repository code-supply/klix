defmodule Klix.WizardTest do
  use Klix.DataCase, async: true

  alias Klix.Wizard

  defmodule Thing do
    use Ecto.Schema

    embedded_schema do
      field :name, :string
      field :description, :string
      field :age, :integer
    end

    def empty_changeset(thing) do
      thing |> Ecto.Changeset.cast(%{}, [])
    end

    def changeset(thing, params) do
      thing
      |> Ecto.Changeset.cast(
        Enum.into(params, %{}),
        [:name, :description, :age]
      )
      |> Ecto.Changeset.validate_required([:name, :description, :age])
    end
  end

  defmodule TestStep1 do
    @behaviour Wizard.Step

    def title, do: "Step 1"
    def struct, do: %Klix.WizardTest.Thing{}
    def cast(thing, params), do: Ecto.Changeset.cast(thing, Enum.into(params, %{}), [:name])

    def validate(changeset) do
      changeset
      |> Ecto.Changeset.validate_required([:name])
    end
  end

  defmodule TestStep2 do
    @behaviour Wizard.Step

    def title, do: "Step 2"
    def struct, do: %Klix.WizardTest.Thing{}

    def cast(thing, params),
      do: Ecto.Changeset.cast(thing, Enum.into(params, %{}), [:description])

    def validate(changeset) do
      changeset
      |> Ecto.Changeset.validate_required([:description])
    end
  end

  defmodule TestStep3 do
    @behaviour Wizard.Step

    def title, do: "Step 3"
    def struct, do: %Klix.WizardTest.Thing{}
    def cast(thing, params), do: Ecto.Changeset.cast(thing, Enum.into(params, %{}), [:age])

    def validate(changeset) do
      changeset
      |> Ecto.Changeset.validate_required([:age])
    end
  end

  test "completing first step produces new incomplete step" do
    wizard = Wizard.new([TestStep1, TestStep2, TestStep3])

    assert wizard.current == TestStep1
    refute wizard.changeset_for_step.valid?

    wizard = Wizard.next(wizard, name: "Andrew")

    assert wizard.current == TestStep2
    refute wizard.changeset_for_step.valid?
    assert wizard.data == nil
  end

  test "completing final step produces data ready for persistence" do
    wizard = Wizard.new([TestStep1, TestStep2, TestStep3])

    refute Wizard.complete?(wizard)

    refute Wizard.changeset_for_step(wizard, TestStep1).valid?

    wizard =
      wizard
      |> Wizard.next(name: "Andrew")
      |> Wizard.next(description: "a person")
      |> Wizard.next(age: 999)

    assert %Thing{
             name: "Andrew",
             description: "a person",
             age: 999
           } = wizard.data

    assert wizard.changeset.changes == %{name: "Andrew", description: "a person", age: 999}

    assert Wizard.complete?(wizard)
  end

  test "can go back" do
    wizard =
      Wizard.new([TestStep1, TestStep2])
      |> Wizard.next(name: "a name")
      |> Wizard.previous()

    assert wizard.current == TestStep1
    assert wizard.changeset_for_step.changes.name == "a name"
  end

  test "going back from first is a no-op" do
    wizard =
      Wizard.new([TestStep1])
      |> Wizard.previous()

    assert wizard.current == TestStep1
  end

  test "errors are available on step changesets" do
    wizard =
      Wizard.new([TestStep1, TestStep2, TestStep3])
      |> Wizard.next(name: "")

    refute wizard.changeset_for_step.valid?
    assert wizard.changeset_for_step.action
    assert wizard.changeset_for_step.errors[:name]

    assert wizard.current == TestStep1
  end
end
