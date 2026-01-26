defmodule KlixWeb.Router do
  use KlixWeb, :router

  import KlixWeb.MachineAuth
  import KlixWeb.UserAuth

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {KlixWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug :fetch_current_scope_for_user
  end

  pipeline :printer do
    plug :fetch_current_scope_for_machine
  end

  scope "/", KlixWeb do
    pipe_through [:browser]

    live_session :current_user,
      on_mount: [{KlixWeb.UserAuth, :mount_current_scope}] do
      live "/", HomeLive

      live "/images/new", BuildNewImageLive
      live "/images/:id", ManageImageLive

      live "/users/register", UserLive.Registration, :new
      live "/users/log-in", UserLive.Login, :new
      live "/users/log-in/:token", UserLive.Confirmation, :new
    end

    get "/docs", DocumentationController, :index
    get "/docs/:section", DocumentationController, :show
    get "/images/:image_id/builds/:id", BuildsController, :download
    post "/users/log-in", UserSessionController, :create
    delete "/users/log-out", UserSessionController, :delete
  end

  if Application.compile_env(:klix, :dev_routes) do
    import Phoenix.LiveDashboard.Router

    scope "/dev" do
      pipe_through :browser

      live_dashboard "/dashboard", metrics: KlixWeb.Telemetry
      forward "/mailbox", Plug.Swoosh.MailboxPreview
    end
  end

  scope "/", KlixWeb do
    pipe_through [:browser, :require_authenticated_user]

    live_session :require_authenticated_user,
      on_mount: [{KlixWeb.UserAuth, :require_authenticated}] do
      live "/users/settings", UserLive.Settings, :edit
      live "/users/settings/confirm-email/:token", UserLive.Settings, :confirm_email

      live "/images", ImagesLive
    end

    post "/users/update-password", UserSessionController, :update_password
  end

  scope "/", KlixWeb do
    pipe_through [:printer]
    get "/images/:uuid/:datetime/:sshsig/config.tar.gz", TarballsController, :download
    put "/images/:uuid/:datetime/:sshsig/versions", VersionsController, :update
  end
end
