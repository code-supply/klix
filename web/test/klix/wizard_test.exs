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

    def changeset(thing, params) do
      Ecto.Changeset.cast(
        thing,
        Enum.into(params, %{}),
        [:name, :description, :age]
      )
    end
  end

  defmodule TestStep1 do
    @behaviour Wizard.Step

    @impl Wizard.Step
    def changeset(parent_changeset, params) do
      parent_changeset
      |> Ecto.Changeset.cast(Enum.into(params, %{}), [:name])
      |> Ecto.Changeset.validate_required([:name])
    end
  end

  defmodule TestStep2 do
    @behaviour Wizard.Step

    @impl Wizard.Step
    def changeset(parent_changeset, params) do
      parent_changeset
      |> Ecto.Changeset.cast(Enum.into(params, %{}), [:description])
      |> Ecto.Changeset.validate_required([:description])
    end
  end

  defmodule TestStep3 do
    @behaviour Wizard.Step

    @impl Wizard.Step
    def changeset(parent_changeset, params) do
      parent_changeset
      |> Ecto.Changeset.cast(Enum.into(params, %{}), [:age])
      |> Ecto.Changeset.validate_required([:age])
    end
  end

  test "completing first step produces new incomplete step" do
    changeset = Thing.changeset(%Thing{}, [])
    wizard = Wizard.new(changeset, [TestStep1, TestStep2, TestStep3])

    refute Wizard.changeset_for_step(wizard, TestStep1).valid?

    wizard = Wizard.next(wizard, name: "Andrew")

    assert Wizard.changeset_for_step(wizard, TestStep1).valid?
    assert wizard.current == TestStep2
    assert wizard.data == nil
  end

  test "completing final step produces data ready for persistence" do
    changeset = Thing.changeset(%Thing{}, [])
    wizard = Wizard.new(changeset, [TestStep1, TestStep2, TestStep3])

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
  end

  test "errors are available on step changesets" do
    changeset = Thing.changeset(%Thing{}, [])

    wizard =
      changeset
      |> Wizard.new([TestStep1, TestStep2, TestStep3])
      |> Wizard.next(name: "")

    refute Wizard.changeset_for_step(wizard, TestStep1).valid?

    assert wizard.current == TestStep1
  end
end
