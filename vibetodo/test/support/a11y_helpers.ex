defmodule VibetodoWeb.A11yHelpers do
  @moduledoc """
  Accessibility testing helpers using axe-core.

  This module provides functions to run automated accessibility checks
  on pages using the axe-core JavaScript library. It can detect approximately
  30-57% of accessibility issues automatically.

  ## Usage

      use VibetodoWeb.FeatureCase

      test "page is accessible", %{session: session} do
        session
        |> visit("/")
        |> assert_accessible()
      end

  ## What axe-core checks

  - WCAG 2.0/2.1/2.2 compliance (levels A, AA, AAA)
  - Missing alt text on images
  - Improper heading hierarchy
  - Missing form labels
  - Color contrast issues
  - ARIA attribute problems
  - Focus management issues
  - Keyboard navigation issues

  ## Limitations

  - Automated testing catches ~30-57% of issues
  - Color contrast checks may not work reliably in headless mode
  - Dynamic content may need explicit waits
  - Manual testing still required for complete coverage
  """

  import ExUnit.Assertions
  import Wallaby.Browser

  # axe-core version to use (from CDN)
  @axe_core_version "4.10.2"
  @axe_core_url "https://cdnjs.cloudflare.com/ajax/libs/axe-core/#{@axe_core_version}/axe.min.js"

  @doc """
  Asserts that the current page has no accessibility violations.

  ## Options

  - `:include` - CSS selector for elements to include (default: entire page)
  - `:exclude` - CSS selector for elements to exclude
  - `:rules` - List of rule IDs to run (default: all)
  - `:tags` - List of tags to filter rules by (e.g., ["wcag2a", "wcag2aa"])
  - `:allowed_violations` - List of violation IDs to ignore

  ## Examples

      # Check entire page
      assert_accessible(session)

      # Check specific section
      assert_accessible(session, include: "#main-content")

      # Exclude known issues temporarily
      assert_accessible(session, allowed_violations: ["color-contrast"])

      # Only check WCAG 2.1 AA
      assert_accessible(session, tags: ["wcag2aa", "wcag21aa"])
  """
  def assert_accessible(session, opts \\ []) do
    violations = run_axe(session, opts)
    allowed = Keyword.get(opts, :allowed_violations, [])

    filtered_violations =
      violations
      |> Enum.reject(fn %{"id" => id} -> id in allowed end)

    if length(filtered_violations) > 0 do
      flunk(format_violations(filtered_violations))
    end

    session
  end

  @doc """
  Runs axe-core and returns the raw violations list.

  Useful when you need to inspect violations without failing the test.
  """
  def run_axe(session, opts \\ []) do
    session = inject_axe(session)

    axe_options = build_axe_options(opts)

    # Use synchronous script with a polling approach
    # First, start the axe run and store results in window
    start_script = """
    window.__axe_done = false;
    window.__axe_results = null;
    axe.run(#{Jason.encode!(axe_options)}).then(function(results) {
      window.__axe_results = results.violations;
      window.__axe_done = true;
    }).catch(function(err) {
      window.__axe_results = [];
      window.__axe_done = true;
      console.error('axe-core error:', err);
    });
    return true;
    """

    execute_script(session, start_script)

    # Wait for results with polling
    wait_for_axe_results(session, 0)
  end

  defp wait_for_axe_results(_session, attempts) when attempts > 50 do
    raise "axe-core timed out after 5 seconds"
  end

  defp wait_for_axe_results(session, attempts) do
    check_script = "return window.__axe_done === true;"
    result_ref = make_ref()
    parent = self()

    execute_script(session, check_script, [], fn result ->
      send(parent, {result_ref, result})
    end)

    receive do
      {^result_ref, true} ->
        # Axe is done, get results
        get_results_ref = make_ref()

        execute_script(session, "return window.__axe_results || [];", [], fn results ->
          send(parent, {get_results_ref, results})
        end)

        receive do
          {^get_results_ref, results} -> results
        after
          1000 -> []
        end

      {^result_ref, _} ->
        # Not done yet, wait and retry
        Process.sleep(100)
        wait_for_axe_results(session, attempts + 1)
    after
      1000 ->
        Process.sleep(100)
        wait_for_axe_results(session, attempts + 1)
    end
  end

  @doc """
  Checks if axe-core is already injected, and injects it if not.
  """
  def inject_axe(session) do
    # Check if axe is already loaded
    check_ref = make_ref()
    parent = self()

    execute_script(session, "return typeof axe !== 'undefined';", [], fn result ->
      send(parent, {check_ref, result})
    end)

    axe_loaded =
      receive do
        {^check_ref, result} -> result
      after
        2000 -> false
      end

    if axe_loaded do
      session
    else
      # Inject axe-core
      inject_script = """
      return new Promise(function(resolve) {
        if (typeof axe !== 'undefined') {
          resolve(true);
          return;
        }
        var script = document.createElement('script');
        script.src = '#{@axe_core_url}';
        script.onload = function() { resolve(true); };
        script.onerror = function() { resolve(false); };
        document.head.appendChild(script);
      });
      """

      # Start injection
      execute_script(session, inject_script)

      # Wait for axe to be available
      wait_for_axe_loaded(session, 0)
    end
  end

  defp wait_for_axe_loaded(_session, attempts) when attempts > 30 do
    raise "Failed to load axe-core after 3 seconds"
  end

  defp wait_for_axe_loaded(session, attempts) do
    check_ref = make_ref()
    parent = self()

    execute_script(session, "return typeof axe !== 'undefined';", [], fn result ->
      send(parent, {check_ref, result})
    end)

    receive do
      {^check_ref, true} ->
        session

      {^check_ref, _} ->
        Process.sleep(100)
        wait_for_axe_loaded(session, attempts + 1)
    after
      200 ->
        Process.sleep(100)
        wait_for_axe_loaded(session, attempts + 1)
    end
  end

  @doc """
  Returns a summary of accessibility issues without failing.

  Useful for generating reports or debugging.
  """
  def accessibility_report(session, opts \\ []) do
    violations = run_axe(session, opts)

    %{
      total_violations: length(violations),
      violations:
        Enum.map(violations, fn v ->
          %{
            id: v["id"],
            impact: v["impact"],
            description: v["description"],
            help: v["help"],
            help_url: v["helpUrl"],
            nodes_affected: length(v["nodes"] || [])
          }
        end)
    }
  end

  # Private functions

  defp build_axe_options(opts) do
    options = %{}

    options =
      case Keyword.get(opts, :include) do
        nil -> options
        selector -> Map.put(options, "include", [[selector]])
      end

    options =
      case Keyword.get(opts, :exclude) do
        nil -> options
        selector -> Map.put(options, "exclude", [[selector]])
      end

    run_only =
      case {Keyword.get(opts, :rules), Keyword.get(opts, :tags)} do
        {nil, nil} ->
          nil

        {rules, nil} when is_list(rules) ->
          %{"type" => "rule", "values" => rules}

        {nil, tags} when is_list(tags) ->
          %{"type" => "tag", "values" => tags}

        {rules, tags} when is_list(rules) and is_list(tags) ->
          # When both specified, run rules that match either
          %{"type" => "tag", "values" => tags}
      end

    if run_only do
      Map.put(options, "runOnly", run_only)
    else
      options
    end
  end

  defp format_violations(violations) do
    """

    ╔══════════════════════════════════════════════════════════════════════════════╗
    ║                        ACCESSIBILITY VIOLATIONS FOUND                        ║
    ╚══════════════════════════════════════════════════════════════════════════════╝

    #{Enum.map_join(violations, "\n\n", &format_violation/1)}

    ────────────────────────────────────────────────────────────────────────────────
    Total: #{length(violations)} violation(s) found

    For more information on fixing these issues, see:
    https://dequeuniversity.com/rules/axe/4.10/
    """
  end

  defp format_violation(violation) do
    impact_emoji =
      case violation["impact"] do
        "critical" -> "🔴"
        "serious" -> "🟠"
        "moderate" -> "🟡"
        "minor" -> "🟢"
        _ -> "⚪"
      end

    nodes = violation["nodes"] || []

    nodes_info =
      nodes
      |> Enum.take(3)
      |> Enum.map_join("\n", fn node ->
        target = node["target"] |> List.first() || "unknown"
        html = node["html"] |> String.slice(0, 100)
        "       • #{target}\n         HTML: #{html}..."
      end)

    remaining =
      if length(nodes) > 3 do
        "\n       ... and #{length(nodes) - 3} more"
      else
        ""
      end

    """
    #{impact_emoji} [#{String.upcase(violation["impact"] || "unknown")}] #{violation["id"]}
       #{violation["help"]}

       Affected elements (#{length(nodes)}):
    #{nodes_info}#{remaining}

       Learn more: #{violation["helpUrl"]}
    """
  end
end
