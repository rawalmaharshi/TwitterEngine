defmodule Proj4.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  def start(_type, _args) do
    # :observer.start
    # numUsers = String.to_integer(Enum.at(System.argv(),0), 10)
    # _numTweets = String.to_integer(Enum.at(System.argv(),1), 10)
    numUsers = 10
    # if numUsers <= 1 do
    #   IO.puts "Please enter the number of users greater than 1"
    #   System.halt(0)
    # end

    twitter_server = Supervisor.child_spec({Proj4.TwitterServer, %{clientProcesses: %{} }}, restart: :transient)
    twitter_client = Enum.reduce(1..numUsers, [], fn x, acc -> 
      currentNode = "#{x}@user"
    [Supervisor.child_spec({Proj4.TwitterClient, %{name: currentNode}}, id: {Proj4.TwitterClient, x}, restart: :temporary) | acc]
    end)

    children = [twitter_server | twitter_client]
    opts = [strategy: :one_for_one, name: Proj4.Supervisor]
    {:ok, application_pid} = Supervisor.start_link(children, opts)

    twitter_server_state = Proj4.TwitterServer.getServerState()
    server_pid = Map.get(twitter_server_state, :server_pid)
    clientProcesses = Map.get(twitter_server_state, :clientProcesses)

    # Register user and login in to the system as well
    Enum.each(clientProcesses, fn {user_name, user_pid}-> 
      Proj4.TwitterClient.register_user(user_name, "random_pass", user_pid, server_pid)
      Proj4.TwitterClient.login_user(user_name, "random_pass", user_pid, server_pid)
    end)
    
    
    # IO.inspect Proj4.TwitterClient.register_user("maharshi", "hello", server_pid)

    # #Login user
    # IO.inspect Proj4.TwitterClient.login_user("maharshi", "hello", server_pid)

    #Get the server ids and name of all the clients in the system
    clientProcesses = Proj4.TwitterServer.get()

    #Randomize sending tweets and all here
    # Process.sleep(10000)
    {:ok, application_pid}
  end
end
