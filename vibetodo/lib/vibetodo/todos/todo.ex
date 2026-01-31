defmodule Vibetodo.Todos.Todo do
  use Ecto.Schema
  import Ecto.Changeset

  schema "todos" do
    field :title, :string
    field :completed, :boolean, default: false
    field :is_next_action, :boolean, default: false
    field :is_someday_maybe, :boolean, default: false
    field :is_today, :boolean, default: false
    field :waiting_for, :string
    field :delegated_at, :utc_datetime

    belongs_to :project, Vibetodo.Projects.Project
    belongs_to :area, Vibetodo.Areas.Area

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(todo, attrs) do
    todo
    |> cast(attrs, [
      :title,
      :completed,
      :project_id,
      :area_id,
      :is_next_action,
      :is_someday_maybe,
      :is_today,
      :waiting_for,
      :delegated_at
    ])
    |> validate_required([:title])
  end
end
