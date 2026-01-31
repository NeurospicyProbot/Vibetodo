defmodule Vibetodo.Todos.Todo do
  use Ecto.Schema
  import Ecto.Changeset

  schema "todos" do
    field :title, :string
    field :completed, :boolean, default: false
    field :is_next_action, :boolean, default: false

    belongs_to :project, Vibetodo.Projects.Project

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(todo, attrs) do
    todo
    |> cast(attrs, [:title, :completed, :project_id, :is_next_action])
    |> validate_required([:title])
  end
end
