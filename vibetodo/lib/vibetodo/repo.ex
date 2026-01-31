defmodule Vibetodo.Repo do
  use Ecto.Repo,
    otp_app: :vibetodo,
    adapter: Ecto.Adapters.SQLite3
end
