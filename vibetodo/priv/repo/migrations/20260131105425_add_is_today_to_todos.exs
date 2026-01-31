defmodule Vibetodo.Repo.Migrations.AddIsTodayToTodos do
  use Ecto.Migration

  def change do
    alter table(:todos) do
      add :is_today, :boolean, default: false, null: false
    end
  end
end
