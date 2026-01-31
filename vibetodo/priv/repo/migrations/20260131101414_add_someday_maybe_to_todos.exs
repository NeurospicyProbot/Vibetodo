defmodule Vibetodo.Repo.Migrations.AddSomedayMaybeToTodos do
  use Ecto.Migration

  def change do
    alter table(:todos) do
      add :is_someday_maybe, :boolean, default: false, null: false
    end
  end
end
