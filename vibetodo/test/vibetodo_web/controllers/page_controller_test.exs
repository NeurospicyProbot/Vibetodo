defmodule VibetodoWeb.PageControllerTest do
  use VibetodoWeb.ConnCase

  describe "GET /" do
    test "redirects to login when not authenticated", %{conn: conn} do
      conn = get(conn, ~p"/")
      assert redirected_to(conn) == ~p"/users/log-in"
    end

    @tag :authenticated
    test "renders homepage when authenticated", %{conn: conn} do
      conn = conn |> log_in_user(Vibetodo.AccountsFixtures.user_fixture())
      conn = get(conn, ~p"/")
      assert html_response(conn, 200) =~ "Vibetodo"
    end
  end
end
