defmodule Vibetodo.Repo.Migrations.CreateAreas do
  use Ecto.Migration

  def change do
    create table(:areas) do
      add :title, :string, null: false
      add :description, :text

      timestamps(type: :utc_datetime)
    end

    # Add area_id to projects
    alter table(:projects) do
      add :area_id, references(:areas, on_delete: :nilify_all)
    end

    # Add area_id to todos
    alter table(:todos) do
      add :area_id, references(:areas, on_delete: :nilify_all)
    end

    create index(:projects, [:area_id])
    create index(:todos, [:area_id])
  end
end
