defmodule Proj4.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  def start(_type, _args) do
    # children = [
    #   # Starts a worker by calling: Proj4.Worker.start_link(arg)
    #   # {Proj4.Worker, arg}
    # ]

    # # See https://hexdocs.pm/elixir/Supervisor.html
    # # for other strategies and supported options
    # opts = [strategy: :one_for_one, name: Proj4.Supervisor]
    # Supervisor.start_link(children, opts)

    Proj4.Supervisor.start_link(self());
  end
end
