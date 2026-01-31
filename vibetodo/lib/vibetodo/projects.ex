defmodule Vibetodo.Projects do
  @moduledoc """
  The Projects context.
  """

  import Ecto.Query, warn: false
  alias Vibetodo.Repo
  alias Vibetodo.Projects.Project

  @doc """
  Returns the list of active projects.
  """
  def list_projects do
    Project
    |> where([p], p.status == "active")
    |> order_by(asc: :inserted_at)
    |> Repo.all()
  end

  @doc """
  Returns all projects including completed ones.
  """
  def list_all_projects do
    Project
    |> order_by(asc: :inserted_at)
    |> Repo.all()
  end

  @doc """
  Gets a single project with its todos.
  """
  def get_project!(id) do
    Project
    |> Repo.get!(id)
    |> Repo.preload(:todos)
  end

  @doc """
  Creates a project.
  """
  def create_project(attrs \\ %{}) do
    %Project{}
    |> Project.changeset(attrs)
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
end
