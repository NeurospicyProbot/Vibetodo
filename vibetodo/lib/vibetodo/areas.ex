defmodule Vibetodo.Areas do
  @moduledoc """
  The Areas context.
  Areas of Focus represent ongoing responsibilities that generate work indefinitely.
  """

  import Ecto.Query, warn: false
  alias Vibetodo.Repo
  alias Vibetodo.Areas.Area

  @doc """
  Returns the list of all areas.
  """
  def list_areas do
    Area
    |> order_by(asc: :inserted_at)
    |> Repo.all()
  end

  @doc """
  Gets a single area with its projects and todos.
  """
  def get_area!(id) do
    Area
    |> Repo.get!(id)
    |> Repo.preload([:projects, :todos])
  end

  @doc """
  Creates an area.
  """
  def create_area(attrs \\ %{}) do
    %Area{}
    |> Area.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates an area.
  """
  def update_area(%Area{} = area, attrs) do
    area
    |> Area.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes an area.
  """
  def delete_area(%Area{} = area) do
    Repo.delete(area)
  end

  @doc """
  Returns area stats (active projects, active todos).
  """
  def get_area_stats(%Area{} = area) do
    area = Repo.preload(area, [:projects, :todos])

    active_projects = Enum.count(area.projects, &(&1.status == "active"))
    active_todos = Enum.count(area.todos, &(!&1.completed))

    %{
      active_projects: active_projects,
      active_todos: active_todos,
      total: active_projects + active_todos
    }
  end

  @doc """
  Marks an area as reviewed (updates last_reviewed_at).
  """
  def mark_reviewed(%Area{} = area) do
    update_area(area, %{last_reviewed_at: DateTime.utc_now()})
  end
end
