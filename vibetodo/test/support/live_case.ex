defmodule VibetodoWeb.LiveCase do
  @moduledoc """
  Test case for LiveView tests.

  Uses Phoenix.LiveViewTest for testing LiveView components
  without requiring a real browser.
  """

  use ExUnit.CaseTemplate

  using do
    quote do
      @endpoint VibetodoWeb.Endpoint

      use VibetodoWeb, :verified_routes

      import Plug.Conn
      import Phoenix.ConnTest
      import Phoenix.LiveViewTest
      import VibetodoWeb.LiveCase
      import VibetodoWeb.StaticA11yHelpers
    end
  end

  setup tags do
    Vibetodo.DataCase.setup_sandbox(tags)
    {:ok, conn: Phoenix.ConnTest.build_conn()}
  end

  @doc """
  Setup helper that registers and logs in users for LiveView tests.
  """
  def register_and_log_in_user(%{conn: conn}) do
    user = Vibetodo.AccountsFixtures.user_fixture()
    scope = Vibetodo.Accounts.Scope.for_user(user)
    token = Vibetodo.Accounts.generate_user_session_token(user)

    conn =
      conn
      |> Phoenix.ConnTest.init_test_session(%{})
      |> Plug.Conn.put_session(:user_token, token)

    %{conn: conn, user: user, scope: scope}
  end
end
