defmodule Vibetodo.Projects.Project do
  use Ecto.Schema
  import Ecto.Changeset

  schema "projects" do
    field :title, :string
    field :status, :string, default: "active"
    field :notes, :string

    belongs_to :area, Vibetodo.Areas.Area
    has_many :todos, Vibetodo.Todos.Todo

    timestamps(type: :utc_datetime)
  end

  @statuses ~w(active completed on_hold)

  @doc false
  def changeset(project, attrs) do
    project
    |> cast(attrs, [:title, :status, :notes, :area_id])
    |> validate_required([:title])
    |> validate_inclusion(:status, @statuses)
  end
end
