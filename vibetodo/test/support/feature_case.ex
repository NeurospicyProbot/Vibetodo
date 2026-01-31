defmodule VibetodoWeb.FeatureCase do
  @moduledoc """
  Test case for browser-based feature tests using Wallaby.

  These tests start a real browser (headless Chrome) and can test
  JavaScript interactions, accessibility, and full user flows.
  """

  use ExUnit.CaseTemplate

  using do
    quote do
      use Wallaby.Feature

      alias Vibetodo.Repo
      alias VibetodoWeb.Router.Helpers, as: Routes

      import Wallaby.Query
      import VibetodoWeb.FeatureCase
      import VibetodoWeb.A11yHelpers
    end
  end

  setup tags do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(Vibetodo.Repo)

    unless tags[:async] do
      Ecto.Adapters.SQL.Sandbox.mode(Vibetodo.Repo, {:shared, self()})
    end

    metadata = Phoenix.Ecto.SQL.Sandbox.metadata_for(Vibetodo.Repo, self())
    {:ok, session} = Wallaby.start_session(metadata: metadata)
    {:ok, session: session}
  end

  @doc """
  Creates a user and logs them in via the session cookie.
  Returns the updated session and user.
  """
  def log_in_user_via_session(session) do
    user = Vibetodo.AccountsFixtures.user_fixture()
    token = Vibetodo.Accounts.generate_user_session_token(user)

    # Visit a page to establish a session, then set the cookie
    session =
      session
      |> Wallaby.Browser.visit("/users/log_in")
      |> Wallaby.Browser.set_cookie("_vibetodo_web_user_token", Base.url_encode64(token))
      |> Wallaby.Browser.visit("/")

    {session, user}
  end
end
