defmodule VibetodoWeb.TodoLive do
  use VibetodoWeb, :live_view

  alias Vibetodo.Todos
  alias Vibetodo.Projects

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:todos, Todos.list_todos())
     |> assign(:projects, Projects.list_projects())
     |> assign(:new_todo, "")
     |> assign(:new_project, "")
     |> assign(:selected_project, nil)
     |> assign(:show_project_form, false)
     |> assign(:view_mode, :inbox)
     |> assign(:processing_index, 0)}
  end

  @impl true
  def handle_event("add", %{"title" => title}, socket) do
    title = String.trim(title)

    if title != "" do
      attrs = %{title: title}

      attrs =
        if socket.assigns.selected_project,
          do: Map.put(attrs, :project_id, socket.assigns.selected_project.id),
          else: attrs

      case Todos.create_todo(attrs) do
        {:ok, _todo} ->
          {:noreply,
           socket
           |> assign(:todos, Todos.list_todos())
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
    todo = Todos.get_todo!(id)
    {:ok, _todo} = Todos.toggle_todo(todo)

    {:noreply,
     socket
     |> assign(:todos, Todos.list_todos())
     |> maybe_refresh_project()}
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    todo = Todos.get_todo!(id)
    {:ok, _todo} = Todos.delete_todo(todo)

    {:noreply,
     socket
     |> assign(:todos, Todos.list_todos())
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
     |> assign(:view_mode, :inbox)}
  end

  @impl true
  def handle_event("select_next_actions", _, socket) do
    {:noreply,
     socket
     |> assign(:selected_project, nil)
     |> assign(:view_mode, :next_actions)}
  end

  @impl true
  def handle_event("select_waiting_for", _, socket) do
    {:noreply,
     socket
     |> assign(:selected_project, nil)
     |> assign(:view_mode, :waiting_for)}
  end

  @impl true
  def handle_event("select_someday_maybe", _, socket) do
    {:noreply,
     socket
     |> assign(:selected_project, nil)
     |> assign(:view_mode, :someday_maybe)}
  end

  @impl true
  def handle_event("mark_waiting_for", %{"id" => id, "person" => person}, socket) do
    person = String.trim(person)

    if person != "" do
      todo = Todos.get_todo!(id)
      {:ok, _} = Todos.mark_waiting_for(todo, person)

      {:noreply,
       socket
       |> assign(:todos, Todos.list_todos())
       |> maybe_refresh_project()}
    else
      {:noreply, socket}
    end
  end

  @impl true
  def handle_event("clear_waiting_for", %{"id" => id}, socket) do
    todo = Todos.get_todo!(id)
    {:ok, _} = Todos.clear_waiting_for(todo)

    {:noreply,
     socket
     |> assign(:todos, Todos.list_todos())
     |> maybe_refresh_project()}
  end

  @impl true
  def handle_event("start_processing", _, socket) do
    {:noreply,
     socket
     |> assign(:selected_project, nil)
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
    todo = Todos.get_todo!(id)
    {:ok, _} = Todos.delete_todo(todo)

    {:noreply,
     socket
     |> assign(:todos, Todos.list_todos())
     |> advance_processing()}
  end

  @impl true
  def handle_event("process_done", %{"id" => id}, socket) do
    todo = Todos.get_todo!(id)
    {:ok, _} = Todos.update_todo(todo, %{completed: true})

    {:noreply,
     socket
     |> assign(:todos, Todos.list_todos())
     |> advance_processing()}
  end

  @impl true
  def handle_event("process_next_action", %{"id" => id}, socket) do
    todo = Todos.get_todo!(id)
    {:ok, _} = Todos.update_todo(todo, %{is_next_action: true})

    {:noreply,
     socket
     |> assign(:todos, Todos.list_todos())
     |> advance_processing()}
  end

  @impl true
  def handle_event("process_someday_maybe", %{"id" => id}, socket) do
    todo = Todos.get_todo!(id)
    {:ok, _} = Todos.update_todo(todo, %{is_someday_maybe: true})

    {:noreply,
     socket
     |> assign(:todos, Todos.list_todos())
     |> advance_processing()}
  end

  @impl true
  def handle_event("process_assign_project", %{"id" => id, "project_id" => project_id}, socket) do
    todo = Todos.get_todo!(id)
    project_id = String.to_integer(project_id)
    {:ok, _} = Todos.update_todo(todo, %{project_id: project_id})

    {:noreply,
     socket
     |> assign(:todos, Todos.list_todos())
     |> advance_processing()}
  end

  @impl true
  def handle_event("process_skip", _, socket) do
    {:noreply, advance_processing(socket)}
  end

  @impl true
  def handle_event("process_waiting_for", %{"todo_id" => id, "person" => person}, socket) do
    person = String.trim(person)

    if person != "" do
      todo = Todos.get_todo!(id)
      {:ok, _} = Todos.mark_waiting_for(todo, person)

      {:noreply,
       socket
       |> assign(:todos, Todos.list_todos())
       |> advance_processing()}
    else
      {:noreply, socket}
    end
  end

  @impl true
  def handle_event("toggle_next_action", %{"id" => id}, socket) do
    todo = Todos.get_todo!(id)
    {:ok, _todo} = Todos.toggle_next_action(todo)

    {:noreply,
     socket
     |> assign(:todos, Todos.list_todos())
     |> maybe_refresh_project()}
  end

  @impl true
  def handle_event("select_project", %{"id" => id}, socket) do
    project = Projects.get_project!(id)

    {:noreply,
     socket
     |> assign(:selected_project, project)
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
  def handle_event("create_project", %{"title" => title}, socket) do
    title = String.trim(title)

    if title != "" do
      case Projects.create_project(%{title: title}) do
        {:ok, _project} ->
          {:noreply,
           socket
           |> assign(:projects, Projects.list_projects())
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
  def handle_event(
        "assign_to_project",
        %{"todo_id" => todo_id, "project_id" => project_id},
        socket
      ) do
    todo = Todos.get_todo!(todo_id)
    project_id = if project_id == "", do: nil, else: String.to_integer(project_id)
    {:ok, _todo} = Todos.update_todo(todo, %{project_id: project_id})

    {:noreply,
     socket
     |> assign(:todos, Todos.list_todos())
     |> maybe_refresh_project()}
  end

  defp maybe_refresh_project(socket) do
    if socket.assigns.selected_project do
      assign(socket, :selected_project, Projects.get_project!(socket.assigns.selected_project.id))
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

  defp get_inbox_items(todos), do: Enum.filter(todos, &is_nil(&1.project_id))

  defp current_processing_item(todos, index) do
    inbox_items = get_inbox_items(todos)
    Enum.at(inbox_items, index)
  end

  defp filtered_todos(todos, nil, :inbox), do: Enum.filter(todos, &is_nil(&1.project_id))

  defp filtered_todos(todos, nil, :next_actions),
    do: Enum.filter(todos, &(&1.is_next_action && !&1.completed))

  defp filtered_todos(todos, nil, :waiting_for),
    do: Enum.filter(todos, &(&1.waiting_for && !&1.completed))

  defp filtered_todos(todos, nil, :someday_maybe),
    do: Enum.filter(todos, &(&1.is_someday_maybe && !&1.completed))

  defp filtered_todos(_todos, project, _view_mode), do: project.todos

  defp next_actions_count(todos), do: Enum.count(todos, &(&1.is_next_action && !&1.completed))

  defp waiting_for_count(todos), do: Enum.count(todos, &(&1.waiting_for && !&1.completed))

  defp someday_maybe_count(todos), do: Enum.count(todos, &(&1.is_someday_maybe && !&1.completed))

  defp inbox_count(todos), do: Enum.count(todos, &is_nil(&1.project_id))

  @impl true
  def render(assigns) do
    ~H"""
    <div
      class="flex h-screen bg-gray-100"
      phx-window-keydown="focus_input"
      phx-key="/"
    >
      <!-- Sidebar -->
      <div class="w-64 bg-white shadow-lg p-4">
        <h2 class="text-lg font-semibold text-gray-700 mb-4">Vibetodo</h2>
        
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
        
    <!-- Projects Header -->
        <div class="flex items-center justify-between mt-6 mb-2">
          <h3 class="text-sm font-medium text-gray-500 uppercase tracking-wide">Projects</h3>
          <button
            phx-click="show_project_form"
            class="text-gray-400 hover:text-gray-600"
          >
            <svg
              xmlns="http://www.w3.org/2000/svg"
              class="h-5 w-5"
              viewBox="0 0 20 20"
              fill="currentColor"
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
          <form phx-submit="create_project" class="mb-2">
            <input
              type="text"
              name="title"
              value={@new_project}
              phx-change="update_project_input"
              placeholder="Project name..."
              class="w-full px-3 py-2 text-sm border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500"
              autofocus
            />
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
      </div>
      
    <!-- Main Content -->
      <div class="flex-1 p-8 overflow-auto">
        <div class="max-w-2xl mx-auto">
          <div class="flex items-center justify-between mb-6">
            <h1 class="text-2xl font-bold text-gray-800">
              <%= cond do %>
                <% @selected_project -> %>
                  {@selected_project.title}
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
              class="flex-1 px-4 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500"
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
                        class="flex-1 px-3 py-2 text-sm border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-cyan-500"
                      />
                      <button
                        type="submit"
                        class="px-3 py-2 bg-cyan-50 text-cyan-600 rounded-lg hover:bg-cyan-100 transition-colors text-sm font-medium"
                      >
                        Delegate
                      </button>
                    </form>
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
          <% else %>
            <ul class="space-y-2">
              <%= for todo <- filtered_todos(@todos, @selected_project, @view_mode) do %>
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
                  
    <!-- Project Selector (only show in Inbox) -->
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
                  >
                    <svg
                      xmlns="http://www.w3.org/2000/svg"
                      class="h-5 w-5"
                      viewBox="0 0 20 20"
                      fill="currentColor"
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

            <%= if filtered_todos(@todos, @selected_project, @view_mode) == [] do %>
              <p class="text-center text-gray-500 mt-8">
                <%= cond do %>
                  <% @selected_project -> %>
                    No tasks in this project yet.
                  <% @view_mode == :next_actions -> %>
                    No next actions. Star items to mark them as next actions!
                  <% @view_mode == :waiting_for -> %>
                    Nothing in Waiting For. Use the clock icon to delegate items.
                  <% @view_mode == :someday_maybe -> %>
                    No someday/maybe items. Park ideas here during processing!
                  <% true -> %>
                    Your inbox is empty. Capture what's on your mind!
                <% end %>
              </p>
            <% end %>

            <p class="text-xs text-gray-400 mt-6 text-center">
              <% todos = filtered_todos(@todos, @selected_project, @view_mode) %>
              {length(todos)} item{if length(todos) != 1, do: "s"} · {Enum.count(
                todos,
                & &1.completed
              )} completed
            </p>
          <% end %>
        </div>
      </div>
    </div>
    """
  end
end
