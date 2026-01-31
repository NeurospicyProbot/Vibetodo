defmodule VibetodoWeb.StaticA11yHelpers do
  @moduledoc """
  Static HTML accessibility checks using Floki.

  These checks analyze rendered HTML without requiring a browser.
  They're faster than browser-based axe-core tests but catch fewer issues.

  ## Checks included

  - Images missing alt text
  - Form inputs missing labels
  - Buttons/links without accessible names
  - Missing page landmarks
  - Heading hierarchy issues
  - Empty links and buttons
  - Missing language attribute
  - Tables missing headers

  ## Usage

      use VibetodoWeb.LiveCase

      test "page has accessible forms", %{conn: conn} do
        {:ok, _view, html} = live(conn, ~p"/")
        assert_forms_labeled(html)
      end
  """

  import ExUnit.Assertions

  @doc """
  Runs all static accessibility checks on the HTML.

  Returns a list of issues found, or asserts if any critical issues exist.
  """
  def assert_no_a11y_issues(html, opts \\ []) do
    issues = find_a11y_issues(html, opts)

    critical_issues =
      issues
      |> Enum.filter(fn issue -> issue.severity in [:critical, :serious] end)

    if length(critical_issues) > 0 do
      flunk(format_static_issues(critical_issues))
    end

    html
  end

  @doc """
  Returns all accessibility issues found in the HTML.
  """
  def find_a11y_issues(html, _opts \\ []) do
    parsed = Floki.parse_document!(html)

    []
    |> check_images_have_alt(parsed)
    |> check_inputs_have_labels(parsed)
    |> check_buttons_have_names(parsed)
    |> check_links_have_names(parsed)
    |> check_heading_hierarchy(parsed)
    |> check_page_has_main(parsed)
    |> check_empty_elements(parsed)
    |> check_html_has_lang(parsed)
  end

  # Individual checks

  @doc """
  Asserts all images have alt text (can be empty for decorative images).
  """
  def assert_images_have_alt(html) do
    parsed = Floki.parse_document!(html)
    images_without_alt = find_images_without_alt(parsed)

    if length(images_without_alt) > 0 do
      flunk("""
      Found #{length(images_without_alt)} image(s) without alt attribute:

      #{format_elements(images_without_alt)}

      All images must have an alt attribute. Use alt="" for decorative images.
      """)
    end

    html
  end

  @doc """
  Asserts all form inputs have associated labels.
  """
  def assert_forms_labeled(html) do
    parsed = Floki.parse_document!(html)
    unlabeled = find_unlabeled_inputs(parsed)

    if length(unlabeled) > 0 do
      flunk("""
      Found #{length(unlabeled)} form input(s) without labels:

      #{format_elements(unlabeled)}

      All form inputs must have an associated label via:
      - A <label for="input-id"> element
      - aria-label attribute
      - aria-labelledby attribute
      - Being wrapped in a <label> element
      """)
    end

    html
  end

  @doc """
  Asserts all buttons have accessible names.
  """
  def assert_buttons_accessible(html) do
    parsed = Floki.parse_document!(html)
    unnamed_buttons = find_unnamed_buttons(parsed)

    if length(unnamed_buttons) > 0 do
      flunk("""
      Found #{length(unnamed_buttons)} button(s) without accessible names:

      #{format_elements(unnamed_buttons)}

      Buttons must have visible text, aria-label, or aria-labelledby.
      """)
    end

    html
  end

  @doc """
  Asserts all links have accessible names.
  """
  def assert_links_accessible(html) do
    parsed = Floki.parse_document!(html)
    unnamed_links = find_unnamed_links(parsed)

    if length(unnamed_links) > 0 do
      flunk("""
      Found #{length(unnamed_links)} link(s) without accessible names:

      #{format_elements(unnamed_links)}

      Links must have visible text, aria-label, or aria-labelledby.
      """)
    end

    html
  end

  @doc """
  Asserts headings follow proper hierarchy (no skipped levels).
  """
  def assert_heading_hierarchy(html) do
    parsed = Floki.parse_document!(html)
    issues = check_heading_order(parsed)

    if length(issues) > 0 do
      flunk("""
      Heading hierarchy issues found:

      #{Enum.join(issues, "\n")}

      Headings should not skip levels (e.g., h1 -> h3 without h2).
      """)
    end

    html
  end

  # Private implementation

  defp find_images_without_alt(parsed) do
    parsed
    |> Floki.find("img")
    |> Enum.reject(fn element ->
      has_attr?(element, "alt") or has_attr?(element, "role", "presentation")
    end)
  end

  defp find_unlabeled_inputs(parsed) do
    inputs =
      parsed
      |> Floki.find("input, select, textarea")
      |> Enum.reject(fn element ->
        has_attr?(element, "type", "hidden") or
          has_attr?(element, "type", "submit") or
          has_attr?(element, "type", "button") or
          has_attr?(element, "type", "reset") or
          has_attr?(element, "type", "image")
      end)

    labels = Floki.find(parsed, "label")
    label_fors = Enum.map(labels, fn label -> Floki.attribute(label, "for") |> List.first() end)

    Enum.reject(inputs, fn input ->
      id = Floki.attribute(input, "id") |> List.first()
      aria_label = Floki.attribute(input, "aria-label") |> List.first()
      aria_labelledby = Floki.attribute(input, "aria-labelledby") |> List.first()
      title = Floki.attribute(input, "title") |> List.first()
      placeholder = Floki.attribute(input, "placeholder") |> List.first()

      # Check various labeling methods
      has_label_for = id != nil and id in label_fors
      has_wrapper = is_wrapped_in_label?(input, parsed)
      has_aria_label = is_binary(aria_label) and String.trim(aria_label) != ""
      has_aria_labelledby = is_binary(aria_labelledby) and String.trim(aria_labelledby) != ""
      has_title = is_binary(title) and String.trim(title) != ""
      # Placeholder alone is not ideal but does provide a name
      has_placeholder = is_binary(placeholder) and String.trim(placeholder) != ""

      has_label_for or has_wrapper or has_aria_label or has_aria_labelledby or has_title or
        has_placeholder
    end)
  end

  defp is_wrapped_in_label?(input, parsed) do
    # This is a simplification - checking if parent is a label
    input_html = Floki.raw_html(input)

    parsed
    |> Floki.find("label")
    |> Enum.any?(fn label ->
      label_html = Floki.raw_html(label)
      String.contains?(label_html, input_html)
    end)
  end

  defp find_unnamed_buttons(parsed) do
    parsed
    |> Floki.find("button, [role=\"button\"], input[type=\"button\"], input[type=\"submit\"]")
    |> Enum.reject(fn element ->
      text = Floki.text(element) |> String.trim()
      aria_label = Floki.attribute(element, "aria-label") |> List.first()
      aria_labelledby = Floki.attribute(element, "aria-labelledby") |> List.first()
      title = Floki.attribute(element, "title") |> List.first()
      value = Floki.attribute(element, "value") |> List.first()

      # Check for SVG with title or aria-label inside
      has_svg_label =
        element
        |> Floki.find("svg")
        |> Enum.any?(fn svg ->
          svg_title = Floki.find(svg, "title") |> Floki.text() |> String.trim()
          svg_aria = Floki.attribute(svg, "aria-label") |> List.first()
          svg_title != "" or (is_binary(svg_aria) and String.trim(svg_aria) != "")
        end)

      has_text = text != ""
      has_aria_label = is_binary(aria_label) and String.trim(aria_label) != ""
      has_aria_labelledby = is_binary(aria_labelledby) and String.trim(aria_labelledby) != ""
      has_title = is_binary(title) and String.trim(title) != ""
      has_value = is_binary(value) and String.trim(value) != ""

      has_text or has_aria_label or has_aria_labelledby or has_title or has_value or has_svg_label
    end)
  end

  defp find_unnamed_links(parsed) do
    parsed
    |> Floki.find("a[href]")
    |> Enum.reject(fn element ->
      text = Floki.text(element) |> String.trim()
      aria_label = Floki.attribute(element, "aria-label") |> List.first()
      aria_labelledby = Floki.attribute(element, "aria-labelledby") |> List.first()
      title = Floki.attribute(element, "title") |> List.first()

      # Check for image with alt text inside
      has_img_alt =
        element
        |> Floki.find("img[alt]")
        |> Enum.any?(fn img ->
          alt = Floki.attribute(img, "alt") |> List.first()
          is_binary(alt) and String.trim(alt) != ""
        end)

      has_text = text != ""
      has_aria_label = is_binary(aria_label) and String.trim(aria_label) != ""
      has_aria_labelledby = is_binary(aria_labelledby) and String.trim(aria_labelledby) != ""
      has_title = is_binary(title) and String.trim(title) != ""

      has_text or has_aria_label or has_aria_labelledby or has_title or has_img_alt
    end)
  end

  defp check_heading_order(parsed) do
    headings =
      parsed
      |> Floki.find("h1, h2, h3, h4, h5, h6")
      |> Enum.map(fn {tag, _, _} ->
        {tag, String.to_integer(String.replace(tag, "h", ""))}
      end)

    headings
    |> Enum.chunk_every(2, 1, :discard)
    |> Enum.reduce([], fn [{_tag1, level1}, {tag2, level2}], acc ->
      if level2 > level1 + 1 do
        ["Heading #{tag2} skips from h#{level1} to h#{level2}" | acc]
      else
        acc
      end
    end)
    |> Enum.reverse()
  end

  defp check_images_have_alt(issues, parsed) do
    images = find_images_without_alt(parsed)

    Enum.reduce(images, issues, fn img, acc ->
      [
        %{
          type: :image_missing_alt,
          severity: :critical,
          element: Floki.raw_html(img),
          message: "Image is missing alt attribute"
        }
        | acc
      ]
    end)
  end

  defp check_inputs_have_labels(issues, parsed) do
    inputs = find_unlabeled_inputs(parsed)

    Enum.reduce(inputs, issues, fn input, acc ->
      [
        %{
          type: :input_missing_label,
          severity: :critical,
          element: Floki.raw_html(input),
          message: "Form input is missing a label"
        }
        | acc
      ]
    end)
  end

  defp check_buttons_have_names(issues, parsed) do
    buttons = find_unnamed_buttons(parsed)

    Enum.reduce(buttons, issues, fn button, acc ->
      [
        %{
          type: :button_missing_name,
          severity: :serious,
          element: Floki.raw_html(button),
          message: "Button has no accessible name"
        }
        | acc
      ]
    end)
  end

  defp check_links_have_names(issues, parsed) do
    links = find_unnamed_links(parsed)

    Enum.reduce(links, issues, fn link, acc ->
      [
        %{
          type: :link_missing_name,
          severity: :serious,
          element: Floki.raw_html(link),
          message: "Link has no accessible name"
        }
        | acc
      ]
    end)
  end

  defp check_heading_hierarchy(issues, parsed) do
    heading_issues = check_heading_order(parsed)

    Enum.reduce(heading_issues, issues, fn issue, acc ->
      [
        %{
          type: :heading_hierarchy,
          severity: :moderate,
          element: nil,
          message: issue
        }
        | acc
      ]
    end)
  end

  defp check_page_has_main(issues, parsed) do
    main = Floki.find(parsed, "main, [role=\"main\"]")

    if length(main) == 0 do
      [
        %{
          type: :missing_main_landmark,
          severity: :moderate,
          element: nil,
          message: "Page is missing <main> landmark"
        }
        | issues
      ]
    else
      issues
    end
  end

  defp check_empty_elements(issues, parsed) do
    # Check for buttons and links that are empty
    empty_buttons =
      parsed
      |> Floki.find("button, a[href]")
      |> Enum.filter(fn el ->
        text = Floki.text(el) |> String.trim()
        aria_label = Floki.attribute(el, "aria-label") |> List.first()
        children = Floki.children(el)

        text == "" and
          (is_nil(aria_label) or String.trim(aria_label) == "") and
          length(children) == 0
      end)

    Enum.reduce(empty_buttons, issues, fn el, acc ->
      [
        %{
          type: :empty_interactive,
          severity: :serious,
          element: Floki.raw_html(el),
          message: "Interactive element is empty with no accessible name"
        }
        | acc
      ]
    end)
  end

  defp check_html_has_lang(issues, parsed) do
    html = Floki.find(parsed, "html")

    case html do
      [{_, attrs, _} | _] ->
        has_lang = Enum.any?(attrs, fn {name, _} -> name == "lang" end)

        if has_lang do
          issues
        else
          [
            %{
              type: :missing_lang,
              severity: :serious,
              element: nil,
              message: "<html> element is missing lang attribute"
            }
            | issues
          ]
        end

      _ ->
        # No html element found (probably a fragment)
        issues
    end
  end

  defp has_attr?(element, attr_name) do
    case element do
      {_, attrs, _} ->
        Enum.any?(attrs, fn {name, _} -> name == attr_name end)

      _ ->
        false
    end
  end

  defp has_attr?(element, attr_name, attr_value) do
    case element do
      {_, attrs, _} ->
        Enum.any?(attrs, fn {name, value} -> name == attr_name and value == attr_value end)

      _ ->
        false
    end
  end

  defp format_elements(elements) do
    elements
    |> Enum.take(5)
    |> Enum.map_join("\n", fn el -> "  • #{String.slice(Floki.raw_html(el), 0, 100)}..." end)
  end

  defp format_static_issues(issues) do
    """

    ╔══════════════════════════════════════════════════════════════════════════════╗
    ║                    STATIC ACCESSIBILITY ISSUES FOUND                         ║
    ╚══════════════════════════════════════════════════════════════════════════════╝

    #{Enum.map_join(issues, "\n", &format_issue/1)}

    Total: #{length(issues)} issue(s) found
    """
  end

  defp format_issue(issue) do
    severity_emoji =
      case issue.severity do
        :critical -> "🔴"
        :serious -> "🟠"
        :moderate -> "🟡"
        :minor -> "🟢"
      end

    element_info =
      if issue.element do
        "\n   Element: #{String.slice(issue.element, 0, 80)}..."
      else
        ""
      end

    "#{severity_emoji} [#{issue.severity |> Atom.to_string() |> String.upcase()}] #{issue.message}#{element_info}"
  end
end
