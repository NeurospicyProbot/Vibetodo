defmodule VibetodoWeb.TodoLive do
  use VibetodoWeb, :live_view

  alias Vibetodo.Todos
  alias Vibetodo.Projects
  alias Vibetodo.Areas

  @review_steps [
    :inbox_zero,
    :next_actions,
    :waiting_for,
    :projects,
    :areas,
    :someday_maybe,
    :capture,
    :complete
  ]

  @impl true
  def mount(_params, _session, socket) do
    user = socket.assigns.current_user

    {:ok,
     socket
     |> assign(:todos, Todos.list_todos(user))
     |> assign(:projects, Projects.list_projects(user))
     |> assign(:areas, Areas.list_areas(user))
     |> assign(:new_todo, "")
     |> assign(:new_project, "")
     |> assign(:new_area, "")
     |> assign(:selected_project, nil)
     |> assign(:selected_area, nil)
     |> assign(:show_project_form, false)
     |> assign(:show_area_form, false)
     |> assign(:view_mode, :inbox)
     |> assign(:processing_index, 0)
     |> assign(:review_step, 0)
     |> assign(:review_project_index, 0)
     |> assign(:review_area_index, 0)}
  end

  @impl true
  def handle_event("add", %{"title" => title}, socket) do
    user = socket.assigns.current_user
    title = String.trim(title)

    if title != "" do
      attrs = %{"title" => title}

      attrs =
        if socket.assigns.selected_project,
          do: Map.put(attrs, "project_id", socket.assigns.selected_project.id),
          else: attrs

      case Todos.create_todo(user, attrs) do
        {:ok, _todo} ->
          {:noreply,
           socket
           |> assign(:todos, Todos.list_todos(user))
           |> assign(:new_todo, "")
           |> maybe_refresh_project()}

        {:error, _changeset} ->
          {:noreply, socket}
      end
    else
      {:noreply, socket}
    end
  end

  @impl true
  def handle_event("toggle", %{"id" => id}, socket) do
    user = socket.assigns.current_user
    todo = Todos.get_todo!(user, id)
    {:ok, _todo} = Todos.toggle_todo(todo)

    {:noreply,
     socket
     |> assign(:todos, Todos.list_todos(user))
     |> maybe_refresh_project()}
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    user = socket.assigns.current_user
    todo = Todos.get_todo!(user, id)
    {:ok, _todo} = Todos.delete_todo(todo)

    {:noreply,
     socket
     |> assign(:todos, Todos.list_todos(user))
     |> maybe_refresh_project()}
  end

  @impl true
  def handle_event("update_input", %{"title" => title}, socket) do
    {:noreply, assign(socket, :new_todo, title)}
  end

  @impl true
  def handle_event("focus_input", _, socket) do
    {:noreply, push_event(socket, "focus-input", %{})}
  end

  @impl true
  def handle_event("select_inbox", _, socket) do
    {:noreply,
     socket
     |> assign(:selected_project, nil)
     |> assign(:selected_area, nil)
     |> assign(:view_mode, :inbox)}
  end

  @impl true
  def handle_event("select_next_actions", _, socket) do
    {:noreply,
     socket
     |> assign(:selected_project, nil)
     |> assign(:selected_area, nil)
     |> assign(:view_mode, :next_actions)}
  end

  @impl true
  def handle_event("select_waiting_for", _, socket) do
    {:noreply,
     socket
     |> assign(:selected_project, nil)
     |> assign(:selected_area, nil)
     |> assign(:view_mode, :waiting_for)}
  end

  @impl true
  def handle_event("select_someday_maybe", _, socket) do
    {:noreply,
     socket
     |> assign(:selected_project, nil)
     |> assign(:selected_area, nil)
     |> assign(:view_mode, :someday_maybe)}
  end

  @impl true
  def handle_event("mark_waiting_for", %{"id" => id, "person" => person}, socket) do
    user = socket.assigns.current_user
    person = String.trim(person)

    if person != "" do
      todo = Todos.get_todo!(user, id)
      {:ok, _} = Todos.mark_waiting_for(todo, person)

      {:noreply,
       socket
       |> assign(:todos, Todos.list_todos(user))
       |> maybe_refresh_project()}
    else
      {:noreply, socket}
    end
  end

  @impl true
  def handle_event("clear_waiting_for", %{"id" => id}, socket) do
    user = socket.assigns.current_user
    todo = Todos.get_todo!(user, id)
    {:ok, _} = Todos.clear_waiting_for(todo)

    {:noreply,
     socket
     |> assign(:todos, Todos.list_todos(user))
     |> maybe_refresh_project()}
  end

  @impl true
  def handle_event("start_processing", _, socket) do
    {:noreply,
     socket
     |> assign(:selected_project, nil)
     |> assign(:selected_area, nil)
     |> assign(:view_mode, :processing)
     |> assign(:processing_index, 0)}
  end

  @impl true
  def handle_event("stop_processing", _, socket) do
    {:noreply,
     socket
     |> assign(:view_mode, :inbox)}
  end

  @impl true
  def handle_event("process_delete", %{"id" => id}, socket) do
    user = socket.assigns.current_user
    todo = Todos.get_todo!(user, id)
    {:ok, _} = Todos.delete_todo(todo)

    {:noreply,
     socket
     |> assign(:todos, Todos.list_todos(user))
     |> advance_processing()}
  end

  @impl true
  def handle_event("process_done", %{"id" => id}, socket) do
    user = socket.assigns.current_user
    todo = Todos.get_todo!(user, id)
    {:ok, _} = Todos.update_todo(todo, %{completed: true})

    {:noreply,
     socket
     |> assign(:todos, Todos.list_todos(user))
     |> advance_processing()}
  end

  @impl true
  def handle_event("process_next_action", %{"id" => id}, socket) do
    user = socket.assigns.current_user
    todo = Todos.get_todo!(user, id)
    {:ok, _} = Todos.update_todo(todo, %{is_next_action: true})

    {:noreply,
     socket
     |> assign(:todos, Todos.list_todos(user))
     |> advance_processing()}
  end

  @impl true
  def handle_event("process_someday_maybe", %{"id" => id}, socket) do
    user = socket.assigns.current_user
    todo = Todos.get_todo!(user, id)
    {:ok, _} = Todos.update_todo(todo, %{is_someday_maybe: true})

    {:noreply,
     socket
     |> assign(:todos, Todos.list_todos(user))
     |> advance_processing()}
  end

  @impl true
  def handle_event("process_assign_project", %{"id" => id, "project_id" => project_id}, socket) do
    user = socket.assigns.current_user
    todo = Todos.get_todo!(user, id)
    project_id = String.to_integer(project_id)
    {:ok, _} = Todos.update_todo(todo, %{project_id: project_id})

    {:noreply,
     socket
     |> assign(:todos, Todos.list_todos(user))
     |> advance_processing()}
  end

  @impl true
  def handle_event("process_skip", _, socket) do
    {:noreply, advance_processing(socket)}
  end

  @impl true
  def handle_event("process_convert_to_project", %{"id" => id}, socket) do
    user = socket.assigns.current_user
    todo = Todos.get_todo!(user, id)

    case Projects.create_project(user, %{"title" => todo.title}) do
      {:ok, _project} ->
        {:ok, _} = Todos.delete_todo(todo)

        {:noreply,
         socket
         |> assign(:todos, Todos.list_todos(user))
         |> assign(:projects, Projects.list_projects(user))
         |> advance_processing()}

      {:error, _changeset} ->
        {:noreply, socket}
    end
  end

  @impl true
  def handle_event("process_waiting_for", %{"todo_id" => id, "person" => person}, socket) do
    user = socket.assigns.current_user
    person = String.trim(person)

    if person != "" do
      todo = Todos.get_todo!(user, id)
      {:ok, _} = Todos.mark_waiting_for(todo, person)

      {:noreply,
       socket
       |> assign(:todos, Todos.list_todos(user))
       |> advance_processing()}
    else
      {:noreply, socket}
    end
  end

  # Weekly Review handlers
  @impl true
  def handle_event("start_weekly_review", _, socket) do
    {:noreply,
     socket
     |> assign(:selected_project, nil)
     |> assign(:selected_area, nil)
     |> assign(:view_mode, :weekly_review)
     |> assign(:review_step, 0)
     |> assign(:review_project_index, 0)
     |> assign(:review_area_index, 0)}
  end

  @impl true
  def handle_event("review_next_step", _, socket) do
    {:noreply, advance_review_step(socket)}
  end

  @impl true
  def handle_event("review_prev_step", _, socket) do
    new_step = max(0, socket.assigns.review_step - 1)
    {:noreply, assign(socket, :review_step, new_step)}
  end

  @impl true
  def handle_event("review_skip_step", _, socket) do
    {:noreply, advance_review_step(socket)}
  end

  @impl true
  def handle_event("exit_weekly_review", _, socket) do
    {:noreply,
     socket
     |> assign(:view_mode, :inbox)
     |> assign(:review_step, 0)}
  end

  @impl true
  def handle_event("review_mark_project", %{"id" => id}, socket) do
    user = socket.assigns.current_user
    project = Projects.get_project!(user, id)
    {:ok, _} = Projects.mark_reviewed(project)

    {:noreply,
     socket
     |> assign(:projects, Projects.list_projects(user))
     |> advance_review_project()}
  end

  @impl true
  def handle_event("review_skip_project", _, socket) do
    {:noreply, advance_review_project(socket)}
  end

  @impl true
  def handle_event("review_mark_area", %{"id" => id}, socket) do
    user = socket.assigns.current_user
    area = Areas.get_area!(user, id)
    {:ok, _} = Areas.mark_reviewed(area)

    {:noreply,
     socket
     |> assign(:areas, Areas.list_areas(user))
     |> advance_review_area()}
  end

  @impl true
  def handle_event("review_skip_area", _, socket) do
    {:noreply, advance_review_area(socket)}
  end

  @impl true
  def handle_event("toggle_next_action", %{"id" => id}, socket) do
    user = socket.assigns.current_user
    todo = Todos.get_todo!(user, id)
    {:ok, _todo} = Todos.toggle_next_action(todo)

    {:noreply,
     socket
     |> assign(:todos, Todos.list_todos(user))
     |> maybe_refresh_project()}
  end

  @impl true
  def handle_event("toggle_today", %{"id" => id}, socket) do
    user = socket.assigns.current_user
    todo = Todos.get_todo!(user, id)
    {:ok, _todo} = Todos.toggle_today(todo)

    {:noreply,
     socket
     |> assign(:todos, Todos.list_todos(user))
     |> maybe_refresh_project()}
  end

  @impl true
  def handle_event("select_today", _, socket) do
    {:noreply,
     socket
     |> assign(:selected_project, nil)
     |> assign(:selected_area, nil)
     |> assign(:view_mode, :today)}
  end

  @impl true
  def handle_event("clear_completed_today", _, socket) do
    user = socket.assigns.current_user
    Todos.clear_completed_today(user)

    {:noreply,
     socket
     |> assign(:todos, Todos.list_todos(user))}
  end

  @impl true
  def handle_event("select_project", %{"id" => id}, socket) do
    user = socket.assigns.current_user
    project = Projects.get_project!(user, id)

    {:noreply,
     socket
     |> assign(:selected_project, project)
     |> assign(:selected_area, nil)
     |> assign(:view_mode, :project)}
  end

  @impl true
  def handle_event("show_project_form", _, socket) do
    {:noreply, assign(socket, :show_project_form, true)}
  end

  @impl true
  def handle_event("hide_project_form", _, socket) do
    {:noreply, assign(socket, :show_project_form, false)}
  end

  @impl true
  def handle_event("create_project", params, socket) do
    user = socket.assigns.current_user
    title = String.trim(params["title"] || "")

    area_id =
      case params["area_id"] do
        "" -> nil
        nil -> nil
        id -> String.to_integer(id)
      end

    if title != "" do
      attrs = %{"title" => title}
      attrs = if area_id, do: Map.put(attrs, "area_id", area_id), else: attrs

      case Projects.create_project(user, attrs) do
        {:ok, _project} ->
          {:noreply,
           socket
           |> assign(:projects, Projects.list_projects(user))
           |> assign(:new_project, "")
           |> assign(:show_project_form, false)}

        {:error, _changeset} ->
          {:noreply, socket}
      end
    else
      {:noreply, socket}
    end
  end

  @impl true
  def handle_event("update_project_input", %{"title" => title}, socket) do
    {:noreply, assign(socket, :new_project, title)}
  end

  @impl true
  def handle_event("select_area", %{"id" => id}, socket) do
    user = socket.assigns.current_user
    area = Areas.get_area!(user, id)

    {:noreply,
     socket
     |> assign(:selected_area, area)
     |> assign(:selected_project, nil)
     |> assign(:view_mode, :area)}
  end

  @impl true
  def handle_event("show_area_form", _, socket) do
    {:noreply, assign(socket, :show_area_form, true)}
  end

  @impl true
  def handle_event("hide_area_form", _, socket) do
    {:noreply, assign(socket, :show_area_form, false)}
  end

  @impl true
  def handle_event("create_area", %{"title" => title}, socket) do
    user = socket.assigns.current_user
    title = String.trim(title)

    if title != "" do
      case Areas.create_area(user, %{"title" => title}) do
        {:ok, _area} ->
          {:noreply,
           socket
           |> assign(:areas, Areas.list_areas(user))
           |> assign(:new_area, "")
           |> assign(:show_area_form, false)}

        {:error, _changeset} ->
          {:noreply, socket}
      end
    else
      {:noreply, socket}
    end
  end

  @impl true
  def handle_event("update_area_input", %{"title" => title}, socket) do
    {:noreply, assign(socket, :new_area, title)}
  end

  @impl true
  def handle_event(
        "assign_to_project",
        %{"todo_id" => todo_id, "project_id" => project_id},
        socket
      ) do
    user = socket.assigns.current_user
    todo = Todos.get_todo!(user, todo_id)
    project_id = if project_id == "", do: nil, else: String.to_integer(project_id)
    {:ok, _todo} = Todos.update_todo(todo, %{project_id: project_id})

    {:noreply,
     socket
     |> assign(:todos, Todos.list_todos(user))
     |> maybe_refresh_project()}
  end

  @impl true
  def handle_event(
        "assign_to_area",
        %{"todo_id" => todo_id, "area_id" => area_id},
        socket
      ) do
    user = socket.assigns.current_user
    todo = Todos.get_todo!(user, todo_id)
    area_id = if area_id == "", do: nil, else: String.to_integer(area_id)
    {:ok, _todo} = Todos.update_todo(todo, %{area_id: area_id})

    {:noreply,
     socket
     |> assign(:todos, Todos.list_todos(user))
     |> maybe_refresh_area()}
  end

  defp maybe_refresh_project(socket) do
    user = socket.assigns.current_user

    if socket.assigns.selected_project do
      assign(
        socket,
        :selected_project,
        Projects.get_project!(user, socket.assigns.selected_project.id)
      )
    else
      socket
    end
  end

  defp maybe_refresh_area(socket) do
    user = socket.assigns.current_user

    if socket.assigns.selected_area do
      assign(socket, :selected_area, Areas.get_area!(user, socket.assigns.selected_area.id))
    else
      socket
    end
  end

  defp advance_processing(socket) do
    inbox_items = get_inbox_items(socket.assigns.todos)
    new_index = socket.assigns.processing_index

    if new_index >= length(inbox_items) do
      socket
      |> assign(:view_mode, :inbox)
      |> assign(:processing_index, 0)
    else
      socket
    end
  end

  defp advance_review_step(socket) do
    max_step = length(@review_steps) - 1
    new_step = min(socket.assigns.review_step + 1, max_step)
    assign(socket, :review_step, new_step)
  end

  defp advance_review_project(socket) do
    projects = socket.assigns.projects
    new_index = socket.assigns.review_project_index + 1

    if new_index >= length(projects) do
      # All projects reviewed, move to next step
      advance_review_step(socket)
      |> assign(:review_project_index, 0)
    else
      assign(socket, :review_project_index, new_index)
    end
  end

  defp advance_review_area(socket) do
    areas = socket.assigns.areas
    new_index = socket.assigns.review_area_index + 1

    if new_index >= length(areas) do
      # All areas reviewed, move to next step
      advance_review_step(socket)
      |> assign(:review_area_index, 0)
    else
      assign(socket, :review_area_index, new_index)
    end
  end

  defp current_review_step(step_index) do
    Enum.at(@review_steps, step_index, :complete)
  end

  defp review_step_name(step) do
    case step do
      :inbox_zero -> "Inbox Zero"
      :next_actions -> "Next Actions"
      :waiting_for -> "Waiting For"
      :projects -> "Projects"
      :areas -> "Areas of Focus"
      :someday_maybe -> "Someday/Maybe"
      :capture -> "Capture New"
      :complete -> "Complete"
    end
  end

  defp get_inbox_items(todos) do
    Enum.filter(todos, fn todo ->
      is_nil(todo.project_id) &&
        !todo.is_next_action &&
        !todo.is_someday_maybe &&
        !todo.waiting_for &&
        !todo.completed
    end)
  end

  defp current_processing_item(todos, index) do
    inbox_items = get_inbox_items(todos)
    Enum.at(inbox_items, index)
  end

  defp filtered_todos(todos, nil, nil, :inbox), do: get_inbox_items(todos)

  defp filtered_todos(todos, nil, nil, :next_actions),
    do: Enum.filter(todos, &(&1.is_next_action && !&1.completed))

  defp filtered_todos(todos, nil, nil, :waiting_for),
    do: Enum.filter(todos, &(&1.waiting_for && !&1.completed))

  defp filtered_todos(todos, nil, nil, :someday_maybe),
    do: Enum.filter(todos, &(&1.is_someday_maybe && !&1.completed))

  defp filtered_todos(todos, nil, nil, :today),
    do: Enum.filter(todos, & &1.is_today)

  defp filtered_todos(_todos, project, _area, :project), do: project.todos

  defp filtered_todos(_todos, _project, area, :area), do: area.todos

  defp filtered_todos(todos, nil, nil, _view_mode), do: todos

  defp next_actions_count(todos), do: Enum.count(todos, &(&1.is_next_action && !&1.completed))

  defp waiting_for_count(todos), do: Enum.count(todos, &(&1.waiting_for && !&1.completed))

  defp someday_maybe_count(todos), do: Enum.count(todos, &(&1.is_someday_maybe && !&1.completed))

  defp inbox_count(todos), do: length(get_inbox_items(todos))

  defp today_count(todos), do: Enum.count(todos, &(&1.is_today && !&1.completed))

  @impl true
  def render(assigns) do
    ~H"""
    <div
      class="flex h-screen bg-gray-100"
      phx-window-keydown="focus_input"
      phx-key="/"
    >
      <!-- Sidebar -->
      <aside class="w-64 bg-white shadow-lg p-4" aria-label="Navigation">
        <h2 class="text-lg font-semibold text-gray-700 mb-4">Vibetodo</h2>
        <nav aria-label="Main navigation">
          
    <!-- Inbox -->
          <button
            phx-click="select_inbox"
            class={"w-full text-left px-3 py-2 rounded-lg mb-1 flex items-center justify-between #{if @view_mode == :inbox, do: "bg-blue-100 text-blue-700", else: "hover:bg-gray-100 text-gray-700"}"}
          >
            <span class="flex items-center gap-2">
              <svg
                xmlns="http://www.w3.org/2000/svg"
                class="h-5 w-5"
                viewBox="0 0 20 20"
                fill="currentColor"
              >
                <path
                  fill-rule="evenodd"
                  d="M5 3a2 2 0 00-2 2v10a2 2 0 002 2h10a2 2 0 002-2V5a2 2 0 00-2-2H5zm0 2h10v7h-2l-1 2H8l-1-2H5V5z"
                  clip-rule="evenodd"
                />
              </svg>
              Inbox
            </span>
            <span class="text-sm text-gray-500">{inbox_count(@todos)}</span>
          </button>
          
    <!-- Today -->
          <button
            phx-click="select_today"
            class={"w-full text-left px-3 py-2 rounded-lg mb-1 flex items-center justify-between #{if @view_mode == :today, do: "bg-orange-100 text-orange-700", else: "hover:bg-gray-100 text-gray-700"}"}
          >
            <span class="flex items-center gap-2">
              <svg
                xmlns="http://www.w3.org/2000/svg"
                class="h-5 w-5"
                viewBox="0 0 20 20"
                fill="currentColor"
              >
                <path
                  fill-rule="evenodd"
                  d="M10 2a1 1 0 011 1v1a1 1 0 11-2 0V3a1 1 0 011-1zm4 8a4 4 0 11-8 0 4 4 0 018 0zm-.464 4.95l.707.707a1 1 0 001.414-1.414l-.707-.707a1 1 0 00-1.414 1.414zm2.12-10.607a1 1 0 010 1.414l-.706.707a1 1 0 11-1.414-1.414l.707-.707a1 1 0 011.414 0zM17 11a1 1 0 100-2h-1a1 1 0 100 2h1zm-7 4a1 1 0 011 1v1a1 1 0 11-2 0v-1a1 1 0 011-1zM5.05 6.464A1 1 0 106.465 5.05l-.708-.707a1 1 0 00-1.414 1.414l.707.707zm1.414 8.486l-.707.707a1 1 0 01-1.414-1.414l.707-.707a1 1 0 011.414 1.414zM4 11a1 1 0 100-2H3a1 1 0 000 2h1z"
                  clip-rule="evenodd"
                />
              </svg>
              Today
            </span>
            <span class="text-sm text-gray-500">{today_count(@todos)}</span>
          </button>
          
    <!-- Next Actions -->
          <button
            phx-click="select_next_actions"
            class={"w-full text-left px-3 py-2 rounded-lg mb-1 flex items-center justify-between #{if @view_mode == :next_actions, do: "bg-amber-100 text-amber-700", else: "hover:bg-gray-100 text-gray-700"}"}
          >
            <span class="flex items-center gap-2">
              <svg
                xmlns="http://www.w3.org/2000/svg"
                class="h-5 w-5"
                viewBox="0 0 20 20"
                fill="currentColor"
              >
                <path d="M9.049 2.927c.3-.921 1.603-.921 1.902 0l1.07 3.292a1 1 0 00.95.69h3.462c.969 0 1.371 1.24.588 1.81l-2.8 2.034a1 1 0 00-.364 1.118l1.07 3.292c.3.921-.755 1.688-1.54 1.118l-2.8-2.034a1 1 0 00-1.175 0l-2.8 2.034c-.784.57-1.838-.197-1.539-1.118l1.07-3.292a1 1 0 00-.364-1.118L2.98 8.72c-.783-.57-.38-1.81.588-1.81h3.461a1 1 0 00.951-.69l1.07-3.292z" />
              </svg>
              Next Actions
            </span>
            <span class="text-sm text-gray-500">{next_actions_count(@todos)}</span>
          </button>
          
    <!-- Waiting For -->
          <button
            phx-click="select_waiting_for"
            class={"w-full text-left px-3 py-2 rounded-lg mb-1 flex items-center justify-between #{if @view_mode == :waiting_for, do: "bg-cyan-100 text-cyan-700", else: "hover:bg-gray-100 text-gray-700"}"}
          >
            <span class="flex items-center gap-2">
              <svg
                xmlns="http://www.w3.org/2000/svg"
                class="h-5 w-5"
                viewBox="0 0 20 20"
                fill="currentColor"
              >
                <path
                  fill-rule="evenodd"
                  d="M10 18a8 8 0 100-16 8 8 0 000 16zm1-12a1 1 0 10-2 0v4a1 1 0 00.293.707l2.828 2.829a1 1 0 101.415-1.415L11 9.586V6z"
                  clip-rule="evenodd"
                />
              </svg>
              Waiting For
            </span>
            <span class="text-sm text-gray-500">{waiting_for_count(@todos)}</span>
          </button>
          
    <!-- Someday/Maybe -->
          <button
            phx-click="select_someday_maybe"
            class={"w-full text-left px-3 py-2 rounded-lg mb-2 flex items-center justify-between #{if @view_mode == :someday_maybe, do: "bg-violet-100 text-violet-700", else: "hover:bg-gray-100 text-gray-700"}"}
          >
            <span class="flex items-center gap-2">
              <svg
                xmlns="http://www.w3.org/2000/svg"
                class="h-5 w-5"
                viewBox="0 0 20 20"
                fill="currentColor"
              >
                <path d="M11 3a1 1 0 10-2 0v1a1 1 0 102 0V3zM15.657 5.757a1 1 0 00-1.414-1.414l-.707.707a1 1 0 001.414 1.414l.707-.707zM18 10a1 1 0 01-1 1h-1a1 1 0 110-2h1a1 1 0 011 1zM5.05 6.464A1 1 0 106.464 5.05l-.707-.707a1 1 0 00-1.414 1.414l.707.707zM5 10a1 1 0 01-1 1H3a1 1 0 110-2h1a1 1 0 011 1zM8 16v-1h4v1a2 2 0 11-4 0zM12 14c.015-.34.208-.646.477-.859a4 4 0 10-4.954 0c.27.213.462.519.476.859h4.002z" />
              </svg>
              Someday/Maybe
            </span>
            <span class="text-sm text-gray-500">{someday_maybe_count(@todos)}</span>
          </button>
          
    <!-- Weekly Review -->
          <button
            phx-click="start_weekly_review"
            class={"w-full text-left px-3 py-2 rounded-lg mt-4 mb-2 flex items-center gap-2 #{if @view_mode == :weekly_review, do: "bg-indigo-100 text-indigo-700", else: "bg-indigo-50 hover:bg-indigo-100 text-indigo-600"}"}
          >
            <svg
              xmlns="http://www.w3.org/2000/svg"
              class="h-5 w-5"
              viewBox="0 0 20 20"
              fill="currentColor"
            >
              <path
                fill-rule="evenodd"
                d="M6 2a1 1 0 00-1 1v1H4a2 2 0 00-2 2v10a2 2 0 002 2h12a2 2 0 002-2V6a2 2 0 00-2-2h-1V3a1 1 0 10-2 0v1H7V3a1 1 0 00-1-1zm0 5a1 1 0 000 2h8a1 1 0 100-2H6z"
                clip-rule="evenodd"
              />
            </svg>
            Weekly Review
          </button>
          
    <!-- Areas of Focus Header -->
          <div class="flex items-center justify-between mt-6 mb-2">
            <h3 class="text-sm font-medium text-gray-500 uppercase tracking-wide">Areas</h3>
            <button
              phx-click="show_area_form"
              class="text-gray-400 hover:text-gray-600"
              aria-label="Add new area"
            >
              <svg
                xmlns="http://www.w3.org/2000/svg"
                class="h-5 w-5"
                viewBox="0 0 20 20"
                fill="currentColor"
                aria-hidden="true"
              >
                <path
                  fill-rule="evenodd"
                  d="M10 3a1 1 0 011 1v5h5a1 1 0 110 2h-5v5a1 1 0 11-2 0v-5H4a1 1 0 110-2h5V4a1 1 0 011-1z"
                  clip-rule="evenodd"
                />
              </svg>
            </button>
          </div>
          
    <!-- New Area Form -->
          <%= if @show_area_form do %>
            <form phx-submit="create_area" class="mb-2">
              <input
                type="text"
                name="title"
                value={@new_area}
                phx-change="update_area_input"
                placeholder="Area name..."
                class="w-full px-3 py-2 text-sm border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-emerald-500 bg-white text-gray-900"
                autofocus
              />
            </form>
          <% end %>
          
    <!-- Areas List -->
          <div class="space-y-1">
            <%= for area <- @areas do %>
              <% stats = Areas.get_area_stats(area) %>
              <button
                phx-click="select_area"
                phx-value-id={area.id}
                class={"w-full text-left px-3 py-2 rounded-lg flex items-center justify-between #{if @selected_area && @selected_area.id == area.id, do: "bg-emerald-100 text-emerald-700", else: "hover:bg-gray-100 text-gray-700"}"}
              >
                <span class="flex items-center gap-2 truncate">
                  <svg
                    xmlns="http://www.w3.org/2000/svg"
                    class="h-4 w-4 flex-shrink-0"
                    viewBox="0 0 20 20"
                    fill="currentColor"
                  >
                    <path d="M5 3a2 2 0 00-2 2v2a2 2 0 002 2h2a2 2 0 002-2V5a2 2 0 00-2-2H5zM5 11a2 2 0 00-2 2v2a2 2 0 002 2h2a2 2 0 002-2v-2a2 2 0 00-2-2H5zM11 5a2 2 0 012-2h2a2 2 0 012 2v2a2 2 0 01-2 2h-2a2 2 0 01-2-2V5zM14 11a1 1 0 011 1v1h1a1 1 0 110 2h-1v1a1 1 0 11-2 0v-1h-1a1 1 0 110-2h1v-1a1 1 0 011-1z" />
                  </svg>
                  <span class="truncate">{area.title}</span>
                </span>
                <span class="text-xs text-gray-500">{stats.total}</span>
              </button>
            <% end %>
          </div>

          <%= if @areas == [] && !@show_area_form do %>
            <p class="text-sm text-gray-400 px-3 py-2">No areas yet</p>
          <% end %>
          
    <!-- Projects Header -->
          <div class="flex items-center justify-between mt-6 mb-2">
            <h3 class="text-sm font-medium text-gray-500 uppercase tracking-wide">Projects</h3>
            <button
              phx-click="show_project_form"
              class="text-gray-400 hover:text-gray-600"
              aria-label="Add new project"
            >
              <svg
                xmlns="http://www.w3.org/2000/svg"
                class="h-5 w-5"
                viewBox="0 0 20 20"
                fill="currentColor"
                aria-hidden="true"
              >
                <path
                  fill-rule="evenodd"
                  d="M10 3a1 1 0 011 1v5h5a1 1 0 110 2h-5v5a1 1 0 11-2 0v-5H4a1 1 0 110-2h5V4a1 1 0 011-1z"
                  clip-rule="evenodd"
                />
              </svg>
            </button>
          </div>
          
    <!-- New Project Form -->
          <%= if @show_project_form do %>
            <form phx-submit="create_project" class="mb-2 space-y-2">
              <input
                type="text"
                name="title"
                value={@new_project}
                phx-change="update_project_input"
                placeholder="Project name..."
                class="w-full px-3 py-2 text-sm border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500 bg-white text-gray-900"
                autofocus
              />
              <%= if @areas != [] do %>
                <select
                  name="area_id"
                  class="w-full px-3 py-2 text-sm border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500"
                >
                  <option value="">No area</option>
                  <%= for area <- @areas do %>
                    <option value={area.id}>{area.title}</option>
                  <% end %>
                </select>
              <% end %>
            </form>
          <% end %>
          
    <!-- Projects List -->
          <div class="space-y-1">
            <%= for project <- @projects do %>
              <% stats = Projects.get_project_stats(project) %>
              <button
                phx-click="select_project"
                phx-value-id={project.id}
                class={"w-full text-left px-3 py-2 rounded-lg flex items-center justify-between #{if @selected_project && @selected_project.id == project.id, do: "bg-blue-100 text-blue-700", else: "hover:bg-gray-100 text-gray-700"}"}
              >
                <span class="flex items-center gap-2 truncate">
                  <svg
                    xmlns="http://www.w3.org/2000/svg"
                    class="h-4 w-4 flex-shrink-0"
                    viewBox="0 0 20 20"
                    fill="currentColor"
                  >
                    <path d="M2 6a2 2 0 012-2h5l2 2h5a2 2 0 012 2v6a2 2 0 01-2 2H4a2 2 0 01-2-2V6z" />
                  </svg>
                  <span class="truncate">{project.title}</span>
                </span>
                <span class="text-xs text-gray-500">{stats.completed}/{stats.total}</span>
              </button>
            <% end %>
          </div>

          <%= if @projects == [] && !@show_project_form do %>
            <p class="text-sm text-gray-400 px-3 py-2">No projects yet</p>
          <% end %>
        </nav>
      </aside>
      
    <!-- Main Content -->
      <main class="flex-1 p-8 overflow-auto">
        <div class="max-w-2xl mx-auto">
          <div class="flex items-center justify-between mb-6">
            <h1 class="text-2xl font-bold text-gray-800">
              <%= cond do %>
                <% @view_mode == :weekly_review -> %>
                  Weekly Review
                <% @view_mode == :today -> %>
                  Today
                <% @selected_project -> %>
                  {@selected_project.title}
                <% @selected_area -> %>
                  {@selected_area.title}
                <% @view_mode == :next_actions -> %>
                  Next Actions
                <% @view_mode == :waiting_for -> %>
                  Waiting For
                <% @view_mode == :someday_maybe -> %>
                  Someday/Maybe
                <% @view_mode == :processing -> %>
                  Processing Inbox
                <% true -> %>
                  Inbox
              <% end %>
            </h1>
            <div class="flex items-center gap-3">
              <%= if @view_mode == :inbox && inbox_count(@todos) > 0 do %>
                <button
                  phx-click="start_processing"
                  class="px-3 py-1 text-sm bg-purple-500 text-white rounded-lg hover:bg-purple-600 transition-colors"
                >
                  Process
                </button>
              <% end %>
              <%= if @view_mode == :processing do %>
                <button
                  phx-click="stop_processing"
                  class="px-3 py-1 text-sm bg-gray-400 text-white rounded-lg hover:bg-gray-500 transition-colors"
                >
                  Exit
                </button>
              <% end %>
              <%= if @view_mode == :today && Enum.any?(@todos, &(&1.is_today && &1.completed)) do %>
                <button
                  phx-click="clear_completed_today"
                  class="px-3 py-1 text-sm bg-orange-500 text-white rounded-lg hover:bg-orange-600 transition-colors"
                >
                  Clear Done
                </button>
              <% end %>
              <span class="text-xs text-gray-400">Press / to capture</span>
            </div>
          </div>

          <form phx-submit="add" class="flex gap-2 mb-6">
            <input
              type="text"
              name="title"
              id="capture-input"
              value={@new_todo}
              phx-change="update_input"
              phx-hook="FocusInput"
              placeholder="What's on your mind?"
              class="flex-1 px-4 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500 bg-white text-gray-900"
              autofocus
            />
            <button
              type="submit"
              class="px-4 py-2 bg-blue-500 text-white rounded-lg hover:bg-blue-600 transition-colors"
            >
              Capture
            </button>
          </form>

          <%= if @view_mode == :processing do %>
            <% current_item = current_processing_item(@todos, @processing_index) %>
            <%= if current_item do %>
              <div class="bg-white rounded-xl shadow-lg p-6 mb-6">
                <div class="text-center mb-6">
                  <p class="text-xs text-gray-400 mb-2">
                    Item {@processing_index + 1} of {inbox_count(@todos)}
                  </p>
                  <h2 class="text-xl font-medium text-gray-800">{current_item.title}</h2>
                </div>

                <div class="border-t pt-6">
                  <p class="text-sm text-gray-500 text-center mb-4">Is this actionable?</p>

                  <div class="grid grid-cols-2 gap-3 mb-4">
                    <button
                      phx-click="process_delete"
                      phx-value-id={current_item.id}
                      class="px-4 py-3 bg-red-50 text-red-600 rounded-lg hover:bg-red-100 transition-colors text-sm font-medium"
                    >
                      Delete
                      <span class="block text-xs font-normal text-red-400">Not actionable</span>
                    </button>
                    <button
                      phx-click="process_done"
                      phx-value-id={current_item.id}
                      class="px-4 py-3 bg-green-50 text-green-600 rounded-lg hover:bg-green-100 transition-colors text-sm font-medium"
                    >
                      Done
                      <span class="block text-xs font-normal text-green-400">&lt; 2 minutes</span>
                    </button>
                  </div>

                  <div class="grid grid-cols-2 gap-3 mb-4">
                    <button
                      phx-click="process_next_action"
                      phx-value-id={current_item.id}
                      class="px-4 py-3 bg-amber-50 text-amber-600 rounded-lg hover:bg-amber-100 transition-colors text-sm font-medium"
                    >
                      Next Action
                      <span class="block text-xs font-normal text-amber-400">Do it soon</span>
                    </button>
                    <button
                      phx-click="process_someday_maybe"
                      phx-value-id={current_item.id}
                      class="px-4 py-3 bg-violet-50 text-violet-600 rounded-lg hover:bg-violet-100 transition-colors text-sm font-medium"
                    >
                      Someday/Maybe
                      <span class="block text-xs font-normal text-violet-400">Not now</span>
                    </button>
                  </div>

                  <div class="mb-4">
                    <button
                      phx-click="process_skip"
                      class="w-full px-4 py-2 bg-gray-50 text-gray-600 rounded-lg hover:bg-gray-100 transition-colors text-sm font-medium"
                    >
                      Skip · Decide later
                    </button>
                  </div>
                  
    <!-- Waiting For -->
                  <div class="border-t pt-4 mb-4">
                    <form phx-submit="process_waiting_for" class="flex gap-2">
                      <input type="hidden" name="todo_id" value={current_item.id} />
                      <input
                        type="text"
                        name="person"
                        placeholder="Waiting for who?"
                        class="flex-1 px-3 py-2 text-sm border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-cyan-500 bg-white text-gray-900"
                      />
                      <button
                        type="submit"
                        class="px-3 py-2 bg-cyan-50 text-cyan-600 rounded-lg hover:bg-cyan-100 transition-colors text-sm font-medium"
                      >
                        Delegate
                      </button>
                    </form>
                  </div>
                  
    <!-- Convert to Project -->
                  <div class="border-t pt-4 mb-4">
                    <button
                      phx-click="process_convert_to_project"
                      phx-value-id={current_item.id}
                      class="w-full px-4 py-2 bg-emerald-50 text-emerald-700 rounded-lg hover:bg-emerald-100 transition-colors text-sm font-medium border border-emerald-200"
                    >
                      Convert to Project
                    </button>
                    <p class="text-xs text-gray-400 mt-1 text-center">
                      Multi-step outcome? Make it a project.
                    </p>
                  </div>

                  <%= if @projects != [] do %>
                    <div class="border-t pt-4">
                      <p class="text-xs text-gray-400 mb-2 text-center">Or assign to a project:</p>
                      <div class="flex flex-wrap gap-2 justify-center">
                        <%= for project <- @projects do %>
                          <button
                            phx-click="process_assign_project"
                            phx-value-id={current_item.id}
                            phx-value-project_id={project.id}
                            class="px-3 py-1 text-sm bg-blue-50 text-blue-600 rounded-lg hover:bg-blue-100 transition-colors"
                          >
                            {project.title}
                          </button>
                        <% end %>
                      </div>
                    </div>
                  <% end %>
                </div>
              </div>
            <% else %>
              <div class="text-center py-12">
                <div class="text-5xl mb-4">🎉</div>
                <h2 class="text-xl font-medium text-gray-800 mb-2">Inbox Zero!</h2>
                <p class="text-gray-500 mb-4">All items have been processed.</p>
                <button
                  phx-click="stop_processing"
                  class="px-4 py-2 bg-purple-500 text-white rounded-lg hover:bg-purple-600 transition-colors"
                >
                  Back to Inbox
                </button>
              </div>
            <% end %>
          <% end %>

          <%= if @view_mode == :weekly_review do %>
            <% step = current_review_step(@review_step) %>
            <div class="bg-white rounded-xl shadow-lg p-6 mb-6">
              <!-- Step indicator -->
              <div class="flex items-center justify-between mb-6">
                <div class="flex items-center gap-2">
                  <%= for {s, i} <- Enum.with_index(@review_steps) do %>
                    <div class={"w-3 h-3 rounded-full #{if i == @review_step, do: "bg-indigo-500", else: if(i < @review_step, do: "bg-indigo-200", else: "bg-gray-200")}"} />
                  <% end %>
                </div>
                <span class="text-sm text-gray-500">
                  Step {@review_step + 1} of {length(@review_steps)}
                </span>
              </div>

              <h2 class="text-xl font-semibold text-gray-800 mb-4 text-center">
                {review_step_name(step)}
              </h2>
              
    <!-- Step content -->
              <%= case step do %>
                <% :inbox_zero -> %>
                  <div class="text-center">
                    <% inbox = inbox_count(@todos) %>
                    <%= if inbox > 0 do %>
                      <p class="text-gray-600 mb-4">
                        You have <span class="font-bold text-indigo-600">{inbox}</span>
                        items in your inbox.
                      </p>
                      <button
                        phx-click="start_processing"
                        class="px-4 py-2 bg-purple-500 text-white rounded-lg hover:bg-purple-600 transition-colors mb-4"
                      >
                        Process Inbox First
                      </button>
                      <p class="text-sm text-gray-400">Or skip to continue the review</p>
                    <% else %>
                      <div class="text-5xl mb-4">✅</div>
                      <p class="text-gray-600">Your inbox is empty. Great job!</p>
                    <% end %>
                  </div>
                <% :next_actions -> %>
                  <div>
                    <% next_actions = Enum.filter(@todos, &(&1.is_next_action && !&1.completed)) %>
                    <%= if next_actions == [] do %>
                      <p class="text-center text-gray-500">No next actions defined.</p>
                    <% else %>
                      <p class="text-gray-600 mb-4 text-center">
                        Review your next actions. Are they still relevant?
                      </p>
                      <ul class="space-y-2">
                        <%= for todo <- next_actions do %>
                          <li class="flex items-center gap-3 p-3 bg-gray-50 rounded-lg">
                            <input
                              type="checkbox"
                              checked={todo.completed}
                              phx-click="toggle"
                              phx-value-id={todo.id}
                              class="w-5 h-5 text-blue-500 rounded"
                            />
                            <span class="flex-1">{todo.title}</span>
                            <button
                              phx-click="toggle_next_action"
                              phx-value-id={todo.id}
                              class="text-xs text-gray-400 hover:text-red-500"
                            >
                              Remove
                            </button>
                          </li>
                        <% end %>
                      </ul>
                    <% end %>
                  </div>
                <% :waiting_for -> %>
                  <div>
                    <% waiting = Enum.filter(@todos, &(&1.waiting_for && !&1.completed)) %>
                    <%= if waiting == [] do %>
                      <p class="text-center text-gray-500">Nothing in Waiting For.</p>
                    <% else %>
                      <p class="text-gray-600 mb-4 text-center">
                        Check on delegated items. Need to follow up?
                      </p>
                      <ul class="space-y-2">
                        <%= for todo <- waiting do %>
                          <li class="flex items-center gap-3 p-3 bg-gray-50 rounded-lg">
                            <span class="flex-1">{todo.title}</span>
                            <span class="text-xs text-cyan-600 bg-cyan-50 px-2 py-1 rounded">
                              {todo.waiting_for}
                            </span>
                            <button
                              phx-click="clear_waiting_for"
                              phx-value-id={todo.id}
                              class="text-xs text-gray-400 hover:text-green-500"
                            >
                              Done
                            </button>
                          </li>
                        <% end %>
                      </ul>
                    <% end %>
                  </div>
                <% :projects -> %>
                  <div>
                    <%= if @projects == [] do %>
                      <p class="text-center text-gray-500">No active projects.</p>
                    <% else %>
                      <% project = Enum.at(@projects, @review_project_index) %>
                      <%= if project do %>
                        <% stats = Projects.get_project_stats(project) %>
                        <div class="text-center mb-4">
                          <p class="text-xs text-gray-400">
                            Project {@review_project_index + 1} of {length(@projects)}
                          </p>
                          <h3 class="text-lg font-medium text-gray-800">{project.title}</h3>
                          <p class="text-sm text-gray-500">
                            {stats.completed}/{stats.total} completed
                          </p>
                        </div>
                        <ul class="space-y-2 mb-4 max-h-48 overflow-auto">
                          <%= for todo <- project.todos do %>
                            <li class="flex items-center gap-2 p-2 bg-gray-50 rounded text-sm">
                              <input
                                type="checkbox"
                                checked={todo.completed}
                                phx-click="toggle"
                                phx-value-id={todo.id}
                                class="w-4 h-4"
                              />
                              <span class={if todo.completed, do: "line-through text-gray-400"}>
                                {todo.title}
                              </span>
                            </li>
                          <% end %>
                        </ul>
                        <p class="text-sm text-gray-500 text-center mb-4">
                          Does this project have a clear next action?
                        </p>
                        <div class="flex gap-2 justify-center">
                          <button
                            phx-click="review_mark_project"
                            phx-value-id={project.id}
                            class="px-4 py-2 bg-green-500 text-white rounded-lg hover:bg-green-600"
                          >
                            Reviewed ✓
                          </button>
                          <button
                            phx-click="review_skip_project"
                            class="px-4 py-2 bg-gray-200 text-gray-700 rounded-lg hover:bg-gray-300"
                          >
                            Skip
                          </button>
                        </div>
                      <% end %>
                    <% end %>
                  </div>
                <% :areas -> %>
                  <div>
                    <%= if @areas == [] do %>
                      <p class="text-center text-gray-500">No areas defined.</p>
                    <% else %>
                      <% area = Enum.at(@areas, @review_area_index) %>
                      <%= if area do %>
                        <% stats = Areas.get_area_stats(area) %>
                        <div class="text-center mb-4">
                          <p class="text-xs text-gray-400">
                            Area {@review_area_index + 1} of {length(@areas)}
                          </p>
                          <h3 class="text-lg font-medium text-gray-800">{area.title}</h3>
                          <p class="text-sm text-gray-500">
                            {stats.active_projects} projects, {stats.active_todos} todos
                          </p>
                        </div>
                        <p class="text-sm text-gray-500 text-center mb-4">
                          Are you giving this area enough attention?
                        </p>
                        <div class="flex gap-2 justify-center">
                          <button
                            phx-click="review_mark_area"
                            phx-value-id={area.id}
                            class="px-4 py-2 bg-green-500 text-white rounded-lg hover:bg-green-600"
                          >
                            Reviewed ✓
                          </button>
                          <button
                            phx-click="review_skip_area"
                            class="px-4 py-2 bg-gray-200 text-gray-700 rounded-lg hover:bg-gray-300"
                          >
                            Skip
                          </button>
                        </div>
                      <% end %>
                    <% end %>
                  </div>
                <% :someday_maybe -> %>
                  <div>
                    <% someday = Enum.filter(@todos, &(&1.is_someday_maybe && !&1.completed)) %>
                    <%= if someday == [] do %>
                      <p class="text-center text-gray-500">No someday/maybe items.</p>
                    <% else %>
                      <p class="text-gray-600 mb-4 text-center">Any of these ready to activate?</p>
                      <ul class="space-y-2">
                        <%= for todo <- someday do %>
                          <li class="flex items-center gap-3 p-3 bg-gray-50 rounded-lg">
                            <span class="flex-1">{todo.title}</span>
                            <button
                              phx-click="toggle_someday_maybe"
                              phx-value-id={todo.id}
                              class="text-xs text-indigo-500 hover:text-indigo-700"
                            >
                              Activate
                            </button>
                            <button
                              phx-click="delete"
                              phx-value-id={todo.id}
                              class="text-xs text-red-400 hover:text-red-600"
                            >
                              Delete
                            </button>
                          </li>
                        <% end %>
                      </ul>
                    <% end %>
                  </div>
                <% :capture -> %>
                  <div class="text-center">
                    <p class="text-gray-600 mb-4">Anything new come up during the review?</p>
                    <form phx-submit="add" class="flex gap-2 max-w-md mx-auto">
                      <input
                        type="text"
                        name="title"
                        value={@new_todo}
                        phx-change="update_input"
                        placeholder="Capture new thoughts..."
                        class="flex-1 px-4 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-indigo-500 bg-white text-gray-900"
                      />
                      <button
                        type="submit"
                        class="px-4 py-2 bg-indigo-500 text-white rounded-lg hover:bg-indigo-600"
                      >
                        Add
                      </button>
                    </form>
                  </div>
                <% :complete -> %>
                  <div class="text-center py-8">
                    <div class="text-5xl mb-4">🎉</div>
                    <h3 class="text-xl font-medium text-gray-800 mb-2">Review Complete!</h3>
                    <p class="text-gray-600 mb-6">You've reviewed all your lists and areas.</p>
                    <button
                      phx-click="exit_weekly_review"
                      class="px-6 py-3 bg-indigo-500 text-white rounded-lg hover:bg-indigo-600"
                    >
                      Finish Review
                    </button>
                  </div>
              <% end %>
              
    <!-- Navigation -->
              <%= if step != :complete do %>
                <div class="flex justify-between mt-8 pt-4 border-t">
                  <button
                    phx-click="review_prev_step"
                    class={"px-4 py-2 rounded-lg #{if @review_step == 0, do: "text-gray-300 cursor-not-allowed", else: "text-gray-600 hover:bg-gray-100"}"}
                    disabled={@review_step == 0}
                  >
                    ← Back
                  </button>
                  <button
                    phx-click="exit_weekly_review"
                    class="px-4 py-2 text-gray-400 hover:text-gray-600"
                  >
                    Exit
                  </button>
                  <button
                    phx-click="review_next_step"
                    class="px-4 py-2 bg-indigo-500 text-white rounded-lg hover:bg-indigo-600"
                  >
                    Next →
                  </button>
                </div>
              <% end %>
            </div>
          <% end %>

          <%= if @view_mode not in [:processing, :weekly_review] do %>
            <ul class="space-y-2">
              <%= for todo <- filtered_todos(@todos, @selected_project, @selected_area, @view_mode) do %>
                <li class="flex items-center gap-3 p-3 bg-white rounded-lg shadow-sm group">
                  <button
                    phx-click="toggle_next_action"
                    phx-value-id={todo.id}
                    class={"flex-shrink-0 #{if todo.is_next_action, do: "text-amber-500", else: "text-gray-300 hover:text-amber-400"}"}
                    title={
                      if todo.is_next_action,
                        do: "Remove from Next Actions",
                        else: "Mark as Next Action"
                    }
                  >
                    <svg
                      xmlns="http://www.w3.org/2000/svg"
                      class="h-5 w-5"
                      viewBox="0 0 20 20"
                      fill="currentColor"
                    >
                      <path d="M9.049 2.927c.3-.921 1.603-.921 1.902 0l1.07 3.292a1 1 0 00.95.69h3.462c.969 0 1.371 1.24.588 1.81l-2.8 2.034a1 1 0 00-.364 1.118l1.07 3.292c.3.921-.755 1.688-1.54 1.118l-2.8-2.034a1 1 0 00-1.175 0l-2.8 2.034c-.784.57-1.838-.197-1.539-1.118l1.07-3.292a1 1 0 00-.364-1.118L2.98 8.72c-.783-.57-.38-1.81.588-1.81h3.461a1 1 0 00.951-.69l1.07-3.292z" />
                    </svg>
                  </button>
                  <button
                    phx-click="toggle_today"
                    phx-value-id={todo.id}
                    class={"flex-shrink-0 #{if todo.is_today, do: "text-orange-500", else: "text-gray-300 hover:text-orange-400"}"}
                    title={if todo.is_today, do: "Remove from Today", else: "Add to Today"}
                  >
                    <svg
                      xmlns="http://www.w3.org/2000/svg"
                      class="h-5 w-5"
                      viewBox="0 0 20 20"
                      fill="currentColor"
                    >
                      <path
                        fill-rule="evenodd"
                        d="M10 2a1 1 0 011 1v1a1 1 0 11-2 0V3a1 1 0 011-1zm4 8a4 4 0 11-8 0 4 4 0 018 0zm-.464 4.95l.707.707a1 1 0 001.414-1.414l-.707-.707a1 1 0 00-1.414 1.414zm2.12-10.607a1 1 0 010 1.414l-.706.707a1 1 0 11-1.414-1.414l.707-.707a1 1 0 011.414 0zM17 11a1 1 0 100-2h-1a1 1 0 100 2h1zm-7 4a1 1 0 011 1v1a1 1 0 11-2 0v-1a1 1 0 011-1zM5.05 6.464A1 1 0 106.465 5.05l-.708-.707a1 1 0 00-1.414 1.414l.707.707zm1.414 8.486l-.707.707a1 1 0 01-1.414-1.414l.707-.707a1 1 0 011.414 1.414zM4 11a1 1 0 100-2H3a1 1 0 000 2h1z"
                        clip-rule="evenodd"
                      />
                    </svg>
                  </button>
                  <input
                    type="checkbox"
                    checked={todo.completed}
                    phx-click="toggle"
                    phx-value-id={todo.id}
                    class="w-5 h-5 text-blue-500 rounded focus:ring-blue-500 cursor-pointer"
                  />
                  <div class="flex-1">
                    <span class={"#{if todo.completed, do: "line-through text-gray-400", else: "text-gray-700"}"}>
                      {todo.title}
                    </span>
                    <%= if todo.waiting_for do %>
                      <span class="ml-2 text-xs text-cyan-600 bg-cyan-50 px-2 py-0.5 rounded">
                        Waiting: {todo.waiting_for}
                      </span>
                    <% end %>
                  </div>
                  
    <!-- Area Selector (only show when not in area view) -->
                  <%= if @selected_area == nil && @areas != [] do %>
                    <select
                      phx-change="assign_to_area"
                      phx-value-todo_id={todo.id}
                      name="area_id"
                      class="text-xs px-2 py-1 border border-gray-200 rounded opacity-0 group-hover:opacity-100 transition-opacity"
                    >
                      <option value="">No area</option>
                      <%= for area <- @areas do %>
                        <option value={area.id} selected={todo.area_id == area.id}>
                          {area.title}
                        </option>
                      <% end %>
                    </select>
                  <% end %>
                  <!-- Project Selector (only show when not in project view) -->
                  <%= if @selected_project == nil && @projects != [] do %>
                    <select
                      phx-change="assign_to_project"
                      phx-value-todo_id={todo.id}
                      name="project_id"
                      class="text-xs px-2 py-1 border border-gray-200 rounded opacity-0 group-hover:opacity-100 transition-opacity"
                    >
                      <option value="">No project</option>
                      <%= for project <- @projects do %>
                        <option value={project.id} selected={todo.project_id == project.id}>
                          {project.title}
                        </option>
                      <% end %>
                    </select>
                  <% end %>

                  <button
                    phx-click="delete"
                    phx-value-id={todo.id}
                    class="opacity-0 group-hover:opacity-100 text-red-500 hover:text-red-700 transition-opacity"
                    aria-label={"Delete task: #{todo.title}"}
                  >
                    <svg
                      xmlns="http://www.w3.org/2000/svg"
                      class="h-5 w-5"
                      viewBox="0 0 20 20"
                      fill="currentColor"
                      aria-hidden="true"
                    >
                      <path
                        fill-rule="evenodd"
                        d="M4.293 4.293a1 1 0 011.414 0L10 8.586l4.293-4.293a1 1 0 111.414 1.414L11.414 10l4.293 4.293a1 1 0 01-1.414 1.414L10 11.414l-4.293 4.293a1 1 0 01-1.414-1.414L8.586 10 4.293 5.707a1 1 0 010-1.414z"
                        clip-rule="evenodd"
                      />
                    </svg>
                  </button>
                </li>
              <% end %>
            </ul>

            <%= if filtered_todos(@todos, @selected_project, @selected_area, @view_mode) == [] do %>
              <p class="text-center text-gray-500 mt-8">
                <%= cond do %>
                  <% @selected_project -> %>
                    No tasks in this project yet.
                  <% @selected_area -> %>
                    No tasks in this area yet.
                  <% @view_mode == :next_actions -> %>
                    No next actions. Star items to mark them as next actions!
                  <% @view_mode == :waiting_for -> %>
                    Nothing in Waiting For. Use the clock icon to delegate items.
                  <% @view_mode == :someday_maybe -> %>
                    No someday/maybe items. Park ideas here during processing!
                  <% @view_mode == :today -> %>
                    No items for today. Click the sun icon on any task to add it!
                  <% true -> %>
                    Your inbox is empty. Capture what's on your mind!
                <% end %>
              </p>
            <% end %>

            <p class="text-xs text-gray-400 mt-6 text-center">
              <% todos = filtered_todos(@todos, @selected_project, @selected_area, @view_mode) %>
              {length(todos)} item{if length(todos) != 1, do: "s"} · {Enum.count(
                todos,
                & &1.completed
              )} completed
            </p>
          <% end %>
        </div>
      </main>
    </div>
    """
  end
end
