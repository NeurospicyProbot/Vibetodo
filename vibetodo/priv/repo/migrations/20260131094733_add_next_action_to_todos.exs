defmodule Vibetodo.Repo.Migrations.AddNextActionToTodos do
  use Ecto.Migration

  def change do
    alter table(:todos) do
      add :is_next_action, :boolean, default: false, null: false
    end
  end
end
