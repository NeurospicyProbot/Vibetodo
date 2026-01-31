defmodule VibetodoWeb.Router do
  use VibetodoWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {VibetodoWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", VibetodoWeb do
    pipe_through :browser

    live "/", TodoLive
  end

  scope "/api", VibetodoWeb do
    pipe_through :api

    get "/health", HealthController, :index
  end
end
