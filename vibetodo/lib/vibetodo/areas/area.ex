defmodule Vibetodo.Areas.Area do
  use Ecto.Schema
  import Ecto.Changeset

  schema "areas" do
    field :title, :string
    field :description, :string
    field :last_reviewed_at, :utc_datetime

    belongs_to :user, Vibetodo.Accounts.User
    has_many :projects, Vibetodo.Projects.Project
    has_many :todos, Vibetodo.Todos.Todo

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(area, attrs) do
    area
    |> cast(attrs, [:title, :description, :user_id, :last_reviewed_at])
    |> validate_required([:title, :user_id])
  end
end
