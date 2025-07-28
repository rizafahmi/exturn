defmodule Exturn.Repo do
  use Ecto.Repo,
    otp_app: :exturn,
    adapter: Ecto.Adapters.SQLite3
end
