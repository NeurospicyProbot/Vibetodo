defmodule Vibetodo.Todos do
  @moduledoc """
  The Todos context.
  """

  import Ecto.Query, warn: false
  alias Vibetodo.Repo
  alias Vibetodo.Todos.Todo
  alias Vibetodo.Accounts.User

  @doc """
  Returns the list of todos for the given user, ordered by insertion time.
  """
  def list_todos(%User{} = user) do
    Todo
    |> where([t], t.user_id == ^user.id)
    |> order_by(asc: :inserted_at)
    |> Repo.all()
  end

  @doc """
  Gets a single todo for the given user.
  Raises `Ecto.NoResultsError` if the Todo does not exist or doesn't belong to user.
  """
  def get_todo!(%User{} = user, id) do
    Todo
    |> where([t], t.user_id == ^user.id)
    |> Repo.get!(id)
  end

  @doc """
  Creates a todo for the given user.
  """
  def create_todo(%User{} = user, attrs \\ %{}) do
    %Todo{}
    |> Todo.changeset(Map.put(attrs, "user_id", user.id))
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
  Returns all next actions for the given user (incomplete todos marked as next action).
  """
  def list_next_actions(%User{} = user) do
    Todo
    |> where([t], t.user_id == ^user.id and t.is_next_action == true and t.completed == false)
    |> order_by(asc: :inserted_at)
    |> Repo.all()
  end

  @doc """
  Returns all waiting for items for the given user (incomplete todos with waiting_for set).
  """
  def list_waiting_for(%User{} = user) do
    Todo
    |> where([t], t.user_id == ^user.id and not is_nil(t.waiting_for) and t.completed == false)
    |> order_by(asc: :delegated_at)
    |> Repo.all()
  end

  @doc """
  Marks a todo as waiting for someone.
  """
  def mark_waiting_for(%Todo{} = todo, person) do
    update_todo(todo, %{waiting_for: person, delegated_at: DateTime.utc_now()})
  end

  @doc """
  Clears waiting for status from a todo.
  """
  def clear_waiting_for(%Todo{} = todo) do
    update_todo(todo, %{waiting_for: nil, delegated_at: nil})
  end

  @doc """
  Returns all someday/maybe items for the given user (incomplete todos marked as someday/maybe).
  """
  def list_someday_maybe(%User{} = user) do
    Todo
    |> where([t], t.user_id == ^user.id and t.is_someday_maybe == true and t.completed == false)
    |> order_by(asc: :inserted_at)
    |> Repo.all()
  end

  @doc """
  Toggles the someday/maybe status of a todo.
  """
  def toggle_someday_maybe(%Todo{} = todo) do
    update_todo(todo, %{is_someday_maybe: !todo.is_someday_maybe})
  end

  @doc """
  Returns all today items for the given user (todos marked for today).
  """
  def list_today(%User{} = user) do
    Todo
    |> where([t], t.user_id == ^user.id and t.is_today == true)
    |> order_by(asc: :inserted_at)
    |> Repo.all()
  end

  @doc """
  Toggles the today status of a todo.
  """
  def toggle_today(%Todo{} = todo) do
    update_todo(todo, %{is_today: !todo.is_today})
  end

  @doc """
  Clears completed items from today for the given user.
  """
  def clear_completed_today(%User{} = user) do
    Todo
    |> where([t], t.user_id == ^user.id and t.is_today == true and t.completed == true)
    |> Repo.update_all(set: [is_today: false])
  end
end
