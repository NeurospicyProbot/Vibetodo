defmodule VibetodoWeb.TodoLive do
  use VibetodoWeb, :live_view

  alias Vibetodo.Todos

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:todos, Todos.list_todos())
     |> assign(:new_todo, "")}
  end

  @impl true
  def handle_event("add", %{"title" => title}, socket) do
    title = String.trim(title)

    if title != "" do
      case Todos.create_todo(%{title: title}) do
        {:ok, _todo} ->
          {:noreply,
           socket
           |> assign(:todos, Todos.list_todos())
           |> assign(:new_todo, "")}

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

    {:noreply, assign(socket, :todos, Todos.list_todos())}
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    todo = Todos.get_todo!(id)
    {:ok, _todo} = Todos.delete_todo(todo)

    {:noreply, assign(socket, :todos, Todos.list_todos())}
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
  def render(assigns) do
    ~H"""
    <div
      class="max-w-md mx-auto mt-10 p-6 bg-white rounded-lg shadow-lg"
      phx-window-keydown="focus_input"
      phx-key="/"
    >
      <div class="flex items-center justify-between mb-6">
        <h1 class="text-2xl font-bold text-gray-800">Inbox</h1>
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
        <%= for todo <- @todos do %>
          <li class="flex items-center gap-3 p-3 bg-gray-50 rounded-lg group">
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

      <%= if @todos == [] do %>
        <p class="text-center text-gray-500 mt-4">Your inbox is empty. Capture what's on your mind!</p>
      <% end %>

      <p class="text-xs text-gray-400 mt-4 text-center">
        <%= length(@todos) %> item<%= if length(@todos) != 1, do: "s" %> to process
      </p>
    </div>
    """
  end
end
