defmodule VibetodoWeb.Features.AccessibilityTest do
  @moduledoc """
  Browser-based accessibility tests using Wallaby and axe-core.

  These tests run in a real headless Chrome browser and use the axe-core
  JavaScript library for comprehensive WCAG compliance checking.

  ## Requirements

  - ChromeDriver must be installed and in PATH
  - Chrome browser must be installed

  ## Running these tests

      # Run all feature tests
      mix test test/vibetodo_web/features/

      # Run just accessibility tests
      mix test test/vibetodo_web/features/accessibility_test.exs

      # Run with visible browser (for debugging)
      WALLABY_HEADLESS=false mix test test/vibetodo_web/features/accessibility_test.exs

  ## Tags

  Tests are tagged with @tag :browser to allow easy filtering:

      # Skip browser tests
      mix test --exclude browser

      # Only browser tests
      mix test --only browser
  """

  use VibetodoWeb.FeatureCase

  @moduletag :browser
  @moduletag timeout: 120_000

  describe "login page accessibility" do
    @tag :browser
    test "login page passes axe-core checks", %{session: session} do
      session
      |> visit("/users/log_in")
      |> assert_accessible(
        # Exclude known issues that may be in third-party components
        allowed_violations: []
      )
    end

    @tag :browser
    test "registration page passes axe-core checks", %{session: session} do
      session
      |> visit("/users/register")
      |> assert_accessible()
    end
  end

  describe "authenticated pages accessibility" do
    @tag :browser
    test "main todo page passes axe-core checks", %{session: session} do
      {session, _user} = log_in_user_via_session(session)

      session
      |> visit("/")
      |> assert_accessible(
        # Run WCAG 2.1 AA checks
        tags: ["wcag2a", "wcag2aa", "wcag21aa"]
      )
    end

    @tag :browser
    test "todo page with items passes axe-core checks", %{session: session} do
      {session, user} = log_in_user_via_session(session)

      # Create test data (use string keys to match API)
      {:ok, _todo1} = Vibetodo.Todos.create_todo(user, %{"title" => "Accessible todo 1"})
      {:ok, _todo2} = Vibetodo.Todos.create_todo(user, %{"title" => "Accessible todo 2"})

      session
      |> visit("/")
      |> assert_has(css("body", text: "Accessible todo 1"))
      |> assert_accessible()
    end

    @tag :browser
    test "processing mode passes axe-core checks", %{session: session} do
      {session, user} = log_in_user_via_session(session)

      # Create inbox item to process (use string keys to match API)
      {:ok, _todo} = Vibetodo.Todos.create_todo(user, %{"title" => "Process me"})

      session
      |> visit("/")
      |> click(button("Process Inbox"))
      |> assert_accessible()
    end

    @tag :browser
    test "weekly review passes axe-core checks", %{session: session} do
      {session, _user} = log_in_user_via_session(session)

      session
      |> visit("/")
      |> click(button("Weekly Review"))
      |> assert_accessible()
    end
  end

  describe "accessibility report generation" do
    @tag :browser
    test "generates accessibility report for main page", %{session: session} do
      {session, _user} = log_in_user_via_session(session)

      session = visit(session, "/")

      report = accessibility_report(session)

      IO.puts("\n")
      IO.puts("═══════════════════════════════════════════════════════════════════")
      IO.puts("                    ACCESSIBILITY REPORT                           ")
      IO.puts("═══════════════════════════════════════════════════════════════════")
      IO.puts("")
      IO.puts("Total violations: #{report.total_violations}")
      IO.puts("")

      if report.total_violations > 0 do
        Enum.each(report.violations, fn v ->
          IO.puts("#{impact_emoji(v.impact)} [#{String.upcase(v.impact)}] #{v.id}")
          IO.puts("   #{v.description}")
          IO.puts("   Affected: #{v.nodes_affected} element(s)")
          IO.puts("   Help: #{v.help_url}")
          IO.puts("")
        end)
      else
        IO.puts("✅ No accessibility violations found!")
      end

      IO.puts("═══════════════════════════════════════════════════════════════════")
      IO.puts("")

      # This test is for reporting, not failing
      assert true
    end
  end

  describe "WCAG compliance levels" do
    @tag :browser
    test "page passes WCAG 2.0 Level A", %{session: session} do
      {session, _user} = log_in_user_via_session(session)

      session
      |> visit("/")
      |> assert_accessible(tags: ["wcag2a"])
    end

    @tag :browser
    test "page passes WCAG 2.0 Level AA", %{session: session} do
      {session, _user} = log_in_user_via_session(session)

      session
      |> visit("/")
      |> assert_accessible(tags: ["wcag2a", "wcag2aa"])
    end

    @tag :browser
    test "page passes WCAG 2.1 Level AA", %{session: session} do
      {session, _user} = log_in_user_via_session(session)

      session
      |> visit("/")
      |> assert_accessible(tags: ["wcag2a", "wcag2aa", "wcag21aa"])
    end
  end

  describe "specific accessibility requirements" do
    @tag :browser
    test "focus is visible on interactive elements", %{session: session} do
      {session, _user} = log_in_user_via_session(session)

      session
      |> visit("/")
      |> assert_accessible(rules: ["focus-visible"])
    end

    @tag :browser
    test "color contrast is sufficient", %{session: session} do
      {session, _user} = log_in_user_via_session(session)

      session
      |> visit("/")
      |> assert_accessible(rules: ["color-contrast"])
    end

    @tag :browser
    test "form labels are present", %{session: session} do
      {session, _user} = log_in_user_via_session(session)

      session
      |> visit("/")
      |> assert_accessible(rules: ["label"])
    end

    @tag :browser
    test "images have alt text", %{session: session} do
      {session, _user} = log_in_user_via_session(session)

      session
      |> visit("/")
      |> assert_accessible(rules: ["image-alt"])
    end
  end

  # Helper functions

  defp impact_emoji(impact) do
    case impact do
      "critical" -> "🔴"
      "serious" -> "🟠"
      "moderate" -> "🟡"
      "minor" -> "🟢"
      _ -> "⚪"
    end
  end
end
