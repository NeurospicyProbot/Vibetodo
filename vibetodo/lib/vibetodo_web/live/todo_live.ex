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
     |> assign(:show_project_form, false)}
  end

  @impl true
  def handle_event("add", %{"title" => title}, socket) do
    title = String.trim(title)

    if title != "" do
      attrs = %{title: title}
      attrs = if socket.assigns.selected_project, do: Map.put(attrs, :project_id, socket.assigns.selected_project.id), else: attrs

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
    {:noreply, assign(socket, :selected_project, nil)}
  end

  @impl true
  def handle_event("select_project", %{"id" => id}, socket) do
    project = Projects.get_project!(id)
    {:noreply, assign(socket, :selected_project, project)}
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
  def handle_event("assign_to_project", %{"todo_id" => todo_id, "project_id" => project_id}, socket) do
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

  defp filtered_todos(todos, nil), do: Enum.filter(todos, &is_nil(&1.project_id))
  defp filtered_todos(_todos, project), do: project.todos

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
          class={"w-full text-left px-3 py-2 rounded-lg mb-2 flex items-center justify-between #{if @selected_project == nil, do: "bg-blue-100 text-blue-700", else: "hover:bg-gray-100 text-gray-700"}"}
        >
          <span class="flex items-center gap-2">
            <svg xmlns="http://www.w3.org/2000/svg" class="h-5 w-5" viewBox="0 0 20 20" fill="currentColor">
              <path fill-rule="evenodd" d="M5 3a2 2 0 00-2 2v10a2 2 0 002 2h10a2 2 0 002-2V5a2 2 0 00-2-2H5zm0 2h10v7h-2l-1 2H8l-1-2H5V5z" clip-rule="evenodd" />
            </svg>
            Inbox
          </span>
          <span class="text-sm text-gray-500"><%= inbox_count(@todos) %></span>
        </button>

        <!-- Projects Header -->
        <div class="flex items-center justify-between mt-6 mb-2">
          <h3 class="text-sm font-medium text-gray-500 uppercase tracking-wide">Projects</h3>
          <button
            phx-click="show_project_form"
            class="text-gray-400 hover:text-gray-600"
          >
            <svg xmlns="http://www.w3.org/2000/svg" class="h-5 w-5" viewBox="0 0 20 20" fill="currentColor">
              <path fill-rule="evenodd" d="M10 3a1 1 0 011 1v5h5a1 1 0 110 2h-5v5a1 1 0 11-2 0v-5H4a1 1 0 110-2h5V4a1 1 0 011-1z" clip-rule="evenodd" />
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
                <svg xmlns="http://www.w3.org/2000/svg" class="h-4 w-4 flex-shrink-0" viewBox="0 0 20 20" fill="currentColor">
                  <path d="M2 6a2 2 0 012-2h5l2 2h5a2 2 0 012 2v6a2 2 0 01-2 2H4a2 2 0 01-2-2V6z" />
                </svg>
                <span class="truncate"><%= project.title %></span>
              </span>
              <span class="text-xs text-gray-500"><%= stats.completed %>/<%= stats.total %></span>
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
              <%= if @selected_project, do: @selected_project.title, else: "Inbox" %>
            </h1>
            <span class="text-xs text-gray-400">Press / to capture</span>
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

          <ul class="space-y-2">
            <%= for todo <- filtered_todos(@todos, @selected_project) do %>
              <li class="flex items-center gap-3 p-3 bg-white rounded-lg shadow-sm group">
                <input
                  type="checkbox"
                  checked={todo.completed}
                  phx-click="toggle"
                  phx-value-id={todo.id}
                  class="w-5 h-5 text-blue-500 rounded focus:ring-blue-500 cursor-pointer"
                />
                <span class={"flex-1 #{if todo.completed, do: "line-through text-gray-400", else: "text-gray-700"}"}>
                  <%= todo.title %>
                </span>

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
                        <%= project.title %>
                      </option>
                    <% end %>
                  </select>
                <% end %>

                <button
                  phx-click="delete"
                  phx-value-id={todo.id}
                  class="opacity-0 group-hover:opacity-100 text-red-500 hover:text-red-700 transition-opacity"
                >
                  <svg xmlns="http://www.w3.org/2000/svg" class="h-5 w-5" viewBox="0 0 20 20" fill="currentColor">
                    <path fill-rule="evenodd" d="M4.293 4.293a1 1 0 011.414 0L10 8.586l4.293-4.293a1 1 0 111.414 1.414L11.414 10l4.293 4.293a1 1 0 01-1.414 1.414L10 11.414l-4.293 4.293a1 1 0 01-1.414-1.414L8.586 10 4.293 5.707a1 1 0 010-1.414z" clip-rule="evenodd" />
                  </svg>
                </button>
              </li>
            <% end %>
          </ul>

          <%= if filtered_todos(@todos, @selected_project) == [] do %>
            <p class="text-center text-gray-500 mt-8">
              <%= if @selected_project do %>
                No tasks in this project yet.
              <% else %>
                Your inbox is empty. Capture what's on your mind!
              <% end %>
            </p>
          <% end %>

          <p class="text-xs text-gray-400 mt-6 text-center">
            <% todos = filtered_todos(@todos, @selected_project) %>
            <%= length(todos) %> item<%= if length(todos) != 1, do: "s" %>
            · <%= Enum.count(todos, & &1.completed) %> completed
          </p>
        </div>
      </div>
    </div>
    """
  end
end
