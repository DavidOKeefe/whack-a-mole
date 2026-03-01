defmodule WhackAMole.Repo do
  use Ecto.Repo,
    otp_app: :whack_a_mole,
    adapter: Ecto.Adapters.Postgres
end
