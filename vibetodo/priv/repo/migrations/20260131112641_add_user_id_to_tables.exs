defmodule Vibetodo.Repo.Migrations.AddUserIdToTables do
  use Ecto.Migration

  def change do
    # Delete existing data that can't be associated with a user
    # This is necessary because we're adding a NOT NULL foreign key
    execute "DELETE FROM todos", ""
    execute "DELETE FROM projects", ""
    execute "DELETE FROM areas", ""

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
