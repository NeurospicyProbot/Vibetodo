defmodule Vibetodo.Todos do
  @moduledoc """
  The Todos context.
  """

  import Ecto.Query, warn: false
  alias Vibetodo.Repo
  alias Vibetodo.Todos.Todo

  @doc """
  Returns the list of todos, ordered by insertion time.
  """
  def list_todos do
    Todo
    |> order_by(asc: :inserted_at)
    |> Repo.all()
  end

  @doc """
  Gets a single todo.
  Raises `Ecto.NoResultsError` if the Todo does not exist.
  """
  def get_todo!(id), do: Repo.get!(Todo, id)

  @doc """
  Creates a todo.
  """
  def create_todo(attrs \\ %{}) do
    %Todo{}
    |> Todo.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a todo.
  """
  def update_todo(%Todo{} = todo, attrs) do
    todo
    |> Todo.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a todo.
  """
  def delete_todo(%Todo{} = todo) do
    Repo.delete(todo)
  end

  @doc """
  Toggles the completed status of a todo.
  """
  def toggle_todo(%Todo{} = todo) do
    update_todo(todo, %{completed: !todo.completed})
  end

  @doc """
  Toggles the next action status of a todo.
  """
  def toggle_next_action(%Todo{} = todo) do
    update_todo(todo, %{is_next_action: !todo.is_next_action})
  end

  @doc """
  Returns all next actions (incomplete todos marked as next action).
  """
  def list_next_actions do
    Todo
    |> where([t], t.is_next_action == true and t.completed == false)
    |> order_by(asc: :inserted_at)
    |> Repo.all()
  end
end
