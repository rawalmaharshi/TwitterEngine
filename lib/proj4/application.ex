defmodule Proj4.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  def start(_type, _args) do

    numUsers = String.to_integer(Enum.at(System.argv(),0), 10)
    _numTweets = String.to_integer(Enum.at(System.argv(),1), 10)

    if numUsers <= 1 do
      IO.puts "Please enter the number of users greater than 1"
      System.halt(0)
    end

    twitter_server = Supervisor.child_spec({Proj4.TwitterServer, []}, restart: :transient)
    twitter_client = Enum.reduce(1..numUsers, [], fn x, acc -> 
      currentNode = "#{x}@user"
    [Supervisor.child_spec({Proj4.TwitterClient, [%{name: currentNode}, x]}, id: {Proj4.TwitterClient, x}, restart: :temporary) | acc]
    end)

    children = [twitter_server | twitter_client]
    opts = [strategy: :one_for_one, name: Proj4.Supervisor]
    Supervisor.start_link(children, opts);
  end
end
