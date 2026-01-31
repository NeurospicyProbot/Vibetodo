defmodule Vibetodo.Projects do
  @moduledoc """
  The Projects context.
  """

  import Ecto.Query, warn: false
  alias Vibetodo.Repo
  alias Vibetodo.Projects.Project
  alias Vibetodo.Accounts.User

  @doc """
  Returns the list of active projects for the given user.
  """
  def list_projects(%User{} = user) do
    Project
    |> where([p], p.user_id == ^user.id and p.status == "active")
    |> order_by(asc: :inserted_at)
    |> Repo.all()
  end

  @doc """
  Returns all projects for the given user including completed ones.
  """
  def list_all_projects(%User{} = user) do
    Project
    |> where([p], p.user_id == ^user.id)
    |> order_by(asc: :inserted_at)
    |> Repo.all()
  end

  @doc """
  Gets a single project with its todos for the given user.
  """
  def get_project!(%User{} = user, id) do
    Project
    |> where([p], p.user_id == ^user.id)
    |> Repo.get!(id)
    |> Repo.preload(:todos)
  end

  @doc """
  Creates a project for the given user.
  """
  def create_project(%User{} = user, attrs \\ %{}) do
    %Project{}
    |> Project.changeset(Map.put(attrs, "user_id", user.id))
    |> Repo.insert()
  end

  @doc """
  Updates a project.
  """
  def update_project(%Project{} = project, attrs) do
    project
    |> Project.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a project.
  """
  def delete_project(%Project{} = project) do
    Repo.delete(project)
  end

  @doc """
  Returns project completion stats.
  """
  def get_project_stats(%Project{} = project) do
    project = Repo.preload(project, :todos)
    total = length(project.todos)
    completed = Enum.count(project.todos, & &1.completed)

    %{
      total: total,
      completed: completed,
      percentage: if(total > 0, do: round(completed / total * 100), else: 0)
    }
  end

  @doc """
  Marks a project as reviewed (updates last_reviewed_at).
  """
  def mark_reviewed(%Project{} = project) do
    update_project(project, %{last_reviewed_at: DateTime.utc_now()})
  end
end
