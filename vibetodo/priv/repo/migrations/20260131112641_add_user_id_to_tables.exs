defmodule Vibetodo.Repo.Migrations.AddUserIdToTables do
  use Ecto.Migration

  def change do
    alter table(:todos) do
      add :user_id, references(:users, on_delete: :delete_all), null: false
    end

    create index(:todos, [:user_id])

    alter table(:projects) do
      add :user_id, references(:users, on_delete: :delete_all), null: false
    end

    create index(:projects, [:user_id])

    alter table(:areas) do
      add :user_id, references(:users, on_delete: :delete_all), null: false
    end

    create index(:areas, [:user_id])
  end
end
