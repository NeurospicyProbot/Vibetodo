defmodule Vibetodo.Repo.Migrations.CreateProjects do
  use Ecto.Migration

  def change do
    create table(:projects) do
      add :title, :string, null: false
      add :status, :string, null: false, default: "active"
      add :notes, :text

      timestamps(type: :utc_datetime)
    end

    # Add project_id to todos
    alter table(:todos) do
      add :project_id, references(:projects, on_delete: :nilify_all)
    end

    create index(:todos, [:project_id])
  end
end
