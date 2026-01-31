defmodule Vibetodo.Areas.Area do
  use Ecto.Schema
  import Ecto.Changeset

  schema "areas" do
    field :title, :string
    field :description, :string

    has_many :projects, Vibetodo.Projects.Project
    has_many :todos, Vibetodo.Todos.Todo

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(area, attrs) do
    area
    |> cast(attrs, [:title, :description])
    |> validate_required([:title])
  end
end
