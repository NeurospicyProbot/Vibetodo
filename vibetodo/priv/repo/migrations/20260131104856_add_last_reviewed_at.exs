defmodule Vibetodo.Repo.Migrations.AddLastReviewedAt do
  use Ecto.Migration

  def change do
    alter table(:projects) do
      add :last_reviewed_at, :utc_datetime
    end

    alter table(:areas) do
      add :last_reviewed_at, :utc_datetime
    end
  end
end
