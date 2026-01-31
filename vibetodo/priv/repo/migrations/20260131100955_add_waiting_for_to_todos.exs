defmodule Vibetodo.Repo.Migrations.AddWaitingForToTodos do
  use Ecto.Migration

  def change do
    alter table(:todos) do
      add :waiting_for, :string
      add :delegated_at, :utc_datetime
    end
  end
end
