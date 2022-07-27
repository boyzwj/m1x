defmodule M1x.Repo do
  use Ecto.Repo,
    otp_app: :m1x,
    adapter: Ecto.Adapters.SQLite3
end
