defmodule KlixWeb.BuildNewImageLive do
  use KlixWeb, :live_view

  alias Klix.{Accounts, Images, Wizard}
  alias Images.Image.Steps

  import KlixWeb.CoreComponents

  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <.header>
        Build New Image
        <:subtitle>
          <div class="breadcrumbs text-sm">
            <ol>
              <li><.link class="link" navigate={~p"/"}>Home</.link></li>
              <li><.link class="link" navigate={~p"/images"}>Your Images</.link></li>
              <li>Build New Image</li>
            </ol>
          </div>
        </:subtitle>
      </.header>

      <ol class="steps py-6 w-full">
        <li
          :for={step <- Klix.Images.Image.Steps.sign_up()}
          class={[step == @wizard.current && "step-primary" | ["step"]]}
        >
          {step.title()}
        </li>
      </ol>

      <.form for={@wizard.changeset_for_step} id="step" phx-submit="next" phx-change="change">
        <.step
          form={to_form(@wizard.changeset_for_step)}
          step={@wizard.current}
          show_immutable_config_options={@show_immutable_config_options}
        />
      </.form>

      <div :if={!@current_scope} role="alert" class="alert alert-info alert-soft mt-6 w-3/4 m-auto">
        <.icon name="hero-information-circle" class="size-8" />
        <p>
          You are not logged in. You can still create images, download and use them.
          To work with multiple printers, please
          <.link class="link" href={~p"/users/log-in"}>log in</.link>
          or <.link class="link" href={~p"/users/register"}>register for an account</.link>.
        </p>
      </div>
    </Layouts.app>
    """
  end

  def mount(_params, _session, socket) do
    {
      :ok,
      assign(socket,
        show_immutable_config_options: false,
        page_title: "Custom 3D Printer OS Image"
      )
    }
  end

  def handle_params(%{"step" => step}, _uri, socket) do
    {
      :noreply,
      assign(
        socket,
        wizard:
          Images.Image.Steps.sign_up()
          |> Wizard.new(
            socket.assigns[:unfinished_image] || current_user(socket).unfinished_image
          )
          |> Wizard.jump(step)
      )
    }
  end

  def handle_params(_params, _uri, socket) do
    {
      :noreply,
      assign(
        socket,
        wizard:
          Images.Image.Steps.sign_up()
          |> Wizard.new(current_user(socket).unfinished_image)
      )
    }
  end

  def handle_event("change", %{"image" => image_params}, socket) do
    {
      :noreply,
      assign(socket,
        show_immutable_config_options: image_params["klipper_config_mutable"] == "false"
      )
    }
  end

  def handle_event(
        "next",
        %{"image" => image_params},
        %{assigns: %{wizard: original_wizard, current_scope: scope}} = socket
      ) do
    new_wizard = Wizard.next(original_wizard, image_params)
    socket = assign(socket, :wizard, new_wizard)

    cond do
      Wizard.complete?(new_wizard) ->
        {:ok, image} = Images.save_finished(scope, new_wizard.changeset)
        {:noreply, push_navigate(socket, to: ~p"/images/#{image.id}")}

      new_wizard.current == original_wizard.current ->
        {:noreply, socket}

      true ->
        advance(socket)
    end
  end

  defp advance(%{assigns: %{wizard: wizard, current_scope: scope}} = socket) do
    socket =
      if wizard.data do
        {:ok, user} = Images.save_unfinished(scope, wizard.data)

        if user.id do
          socket
          |> update(:current_scope, &%{&1 | user: user})
          |> update(:wizard, &%{&1 | data: user.unfinished_image})
        else
          assign(socket, :unfinished_image, user.unfinished_image)
        end
      else
        socket
      end

    step_name = Module.split(wizard.current) |> List.last()

    {:noreply, push_patch(socket, to: ~p"/images/new?step=#{step_name}")}
  end

  defp current_user(%{assigns: %{current_scope: nil}, unfinished_image: image}) do
    %Accounts.User{unfinished_image: image}
  end

  defp current_user(%{assigns: %{current_scope: nil}}) do
    %Accounts.User{unfinished_image: nil}
  end

  defp current_user(socket) do
    Klix.Repo.preload(socket.assigns.current_scope.user, :unfinished_image)
  end

  attr :form, Phoenix.HTML.Form
  attr :step, :integer
  attr :show_immutable_config_options, :boolean

  defp step(%{step: Steps.Machine} = assigns) do
    ~H"""
    <div class="card bg-base-100 w-3/4 m-auto">
      <div class="card-body">
        <h2 class="card-title">What kind of machine is this image for?</h2>
        <p>
          Klix currently supports Raspberry Pi 4 and 5. Images are not
          interchangeable between these versions, so you need to tell us which
          board you have.
        </p>
        <p>
          If you don't yet have a board, we recommend the Pi 4 as it's better
          supported by open-source software.
        </p>
        <.input
          field={@form[:machine]}
          type="select"
          prompt="--Choose--"
          options={Klix.Images.Image.options_for_machine()}
          label="Machine type"
          class="w-50 select"
        />
        <div class="card-actions justify-end">
          <button id="next" class="btn btn-lg btn-primary">
            Next <.icon name="hero-arrow-right" class="size-6 shrink-0" />
          </button>
        </div>
      </div>
    </div>
    """
  end

  defp step(%{step: Steps.LocaleAndIdentity} = assigns) do
    ~H"""
    <div class="card bg-base-100 w-3/4 m-auto">
      <div class="card-body">
        <h2 class="card-title">Locale and Identity</h2>
        <p>
          Your machine's hostname may be used to identify itself on the
          network. Some routers may be configured to automatically route requests
          to the hostname you choose.
        </p>
        <p>
          It could just be the pet name of your printer.
        </p>
        <div class="flex flex-cols-2 gap-7">
          <.input label="Hostname" placeholder="printy-mc-printface" field={@form[:hostname]} />
          <.input
            label="Time zone"
            placeholder="Europe/London"
            field={@form[:timezone]}
            type="select"
            options={Tzdata.zone_list()}
          />
        </div>
        <div class="card-actions justify-between">
          <.link id="prev" patch={~p"/images/new?step=Machine"} class="btn btn-lg btn-neutral">
            <.icon name="hero-arrow-left" class="size-6 shrink-0" /> Previous
          </.link>
          <button id="next" class="btn btn-lg btn-primary">
            Next <.icon name="hero-arrow-right" class="size-6 shrink-0" />
          </button>
        </div>
      </div>
    </div>
    """
  end

  defp step(%{step: Steps.Authentication} = assigns) do
    ~H"""
    <div class="card bg-base-100 w-3/4 m-auto">
      <div class="card-body">
        <h2 class="card-title">How you'll log in</h2>
        <p>
          An SSH key is a secure way to log in to your printer.
          You will use this key for maintenance.
          If you don't have an SSH key yet, you can <.link
            class="link"
            href="https://www.ssh.com/academy/ssh/keygen"
          >generate one</.link>.
        </p>
        <p>
          <code>ssh-add -L</code> will print your public key if you have an SSH agent running.
        </p>
        <p class="font-bold">
          Be sure to only paste the public key. The filename usually ends with <code>.pub</code>.
        </p>
        <div>
          <.input
            type="textarea"
            label="SSH public key"
            field={@form[:public_key]}
            rows="10"
          />
        </div>
        <div class="card-actions justify-between">
          <.link
            id="prev"
            patch={~p"/images/new?step=LocaleAndIdentity"}
            class="btn btn-lg btn-neutral"
          >
            <.icon name="hero-arrow-left" class="size-6 shrink-0" /> Previous
          </.link>
          <button id="next" class="btn btn-lg btn-primary">
            Next <.icon name="hero-arrow-right" class="size-6 shrink-0" />
          </button>
        </div>
      </div>
    </div>
    """
  end

  defp step(%{step: Steps.ExtraSoftware} = assigns) do
    ~H"""
    <div class="card bg-base-100 w-3/4 m-auto">
      <div class="card-body">
        <h2 class="card-title">More software</h2>
        <p>
          <.link class="link" href="https://www.klipper3d.org/">Klipper</.link>,
          <.link class="link" href="https://moonraker.readthedocs.io/en/latest/">Moonraker</.link>
          and <.link class="link" href="https://docs.fluidd.xyz/">Fluidd</.link>
          are included as standard.
        </p>
        <div class="flex flex-wrap gap-6">
          <.input label="KAMP" field={@form[:plugin_kamp_enabled]} type="checkbox" />
          <.input label="Shaketune" field={@form[:plugin_shaketune_enabled]} type="checkbox" />
          <.input
            label="Z Calibration"
            field={@form[:plugin_z_calibration_enabled]}
            type="checkbox"
          />
          <.input label="KlipperScreen" field={@form[:klipperscreen_enabled]} type="checkbox" />
        </div>
        <div class="card-actions justify-between">
          <.link id="prev" patch={~p"/images/new?step=Authentication"} class="btn btn-lg btn-neutral">
            <.icon name="hero-arrow-left" class="size-6 shrink-0" /> Previous
          </.link>
          <button id="next" class="btn btn-lg btn-primary">
            Next <.icon name="hero-arrow-right" class="size-6 shrink-0" />
          </button>
        </div>
      </div>
    </div>
    """
  end

  defp step(%{step: Steps.KlipperConfig} = assigns) do
    ~H"""
    <div class="card bg-base-100 w-3/4 m-auto">
      <div class="card-body">
        <h2 class="card-title">Printer-specific config</h2>
        <.input
          id="mutable_klipper_config"
          label="Mutable Klipper config"
          type="checkbox"
          name="image[klipper_config_mutable]"
          checked={!@show_immutable_config_options}
        />

        <%= if @show_immutable_config_options do %>
          <p>
            Your Klipper config will be pulled from this repo. At present, it
            must be publically viewable.
          </p>
          <p>
            It won't be editable through the Fluidd UI.
          </p>
          <p>
            The "path to config dir" needs to point to the dir inside your repo that contains your <code>printer.cfg</code>.
            If it's in the root of your repo, you don't need to specify it.
          </p>

          <.inputs_for :let={klipper_config} field={@form[:klipper_config]}>
            <.input
              label="Repo type"
              field={klipper_config[:type]}
              type="select"
              options={Klix.Images.KlipperConfig.type_options()}
            />
            <.input label="Repo owner" field={klipper_config[:owner]} />
            <.input label="Repo name" field={klipper_config[:repo]} />
            <.input label="Path to config dir (optional)" field={klipper_config[:path]} />
          </.inputs_for>
        <% else %>
          <p>
            Your Klipper config will be editable on the machine, and you will be
            able to use the Fluidd interface to edit it. It will start with an
            empty config.
          </p>
        <% end %>

        <div :if={@show_immutable_config_options} class="flex flex-col gap-y-3"></div>

        <div class="card-actions justify-between">
          <.link id="prev" patch={~p"/images/new?step=ExtraSoftware"} class="btn btn-lg btn-neutral">
            <.icon name="hero-arrow-left" class="size-6 shrink-0" /> Previous
          </.link>
          <button id="next" class="btn btn-lg btn-primary">
            Finish <.icon name="hero-arrow-right" class="size-6 shrink-0" />
          </button>
        </div>
      </div>
    </div>
    """
  end
end
