defmodule Proj4 do
  
  def main(args \\ []) do
    startProject(args)
  end

  def startProject(args) do
    [numUsers, numTweets] = args
    twitter_server = Supervisor.child_spec({Proj4.TwitterServer, %{clientProcesses: %{} }}, restart: :transient)
    twitter_client = Enum.reduce(1..numUsers, [], fn x, acc -> 
      currentNode = "#{x}@user"
    [Supervisor.child_spec({Proj4.TwitterClient, %{name: currentNode}}, id: {Proj4.TwitterClient, x}, restart: :temporary) | acc]
    end)

    children = [twitter_server | twitter_client]
    opts = [strategy: :one_for_one, name: Proj4.Supervisor]
    {:ok, _application_pid} = Supervisor.start_link(children, opts)

    twitter_server_state = Proj4.TwitterServer.getServerState()
    server_pid = Map.get(twitter_server_state, :server_pid)
    clientProcesses = Map.get(twitter_server_state, :clientProcesses)
    user_names = Map.keys clientProcesses

    defaultTweets = ["Hello", "World", "Twitter Project", "University of Florida", "CISE", "DOS", "COP5615"]
    defaultHashtags = ["#YOLO", "#Wanderlust", "#SportsIsLife"]
    defaultPasswords = ["strong", "weak", "superstrong", "medium"]
    _defaultListOfOperations = ["login", "register", "send_tweets", "subscribe", "unsubscribe"]

    # Register user and login in to the system as well
    :ets.new(:tweets_count, [:set, :protected, :named_table])
    Enum.each(clientProcesses, fn {user_name, user_pid} -> 
      password = Enum.random(defaultPasswords)
      Proj4.TwitterClient.register_user(user_name, password, user_pid, server_pid)
      Proj4.TwitterClient.login_user(user_name, password, user_pid, server_pid)
      :ets.insert(:tweets_count, {user_name, 0})
    end)

    # start time of tweet sending mechanism
    start_time = System.monotonic_time(:millisecond)

    #All the users send tweets (numTweets times) that gets logged into the server
    Enum.each(user_names, fn user -> 
      Enum.each(1..numTweets, fn _tweetsCount -> 
        randomTweetMessage = Enum.random(defaultTweets) <> " " <> Enum.random(defaultHashtags)
        #send tweets
        task = Task.async(fn -> 
          Proj4.TwitterClient.send_tweet(user, randomTweetMessage, Proj4.TwitterClient.get_client_pid_from_username(user), server_pid)
        # :ets.insert(:tweets_count, {user, tweetsCount})
        end)
        Task.await(task, :infinity)
      end)
    end)

    # computing the final time
    IO.puts("Time after #{numUsers} users have sent #{numTweets} tweets: " <> to_string(System.monotonic_time(:millisecond) - start_time) <> " milliseconds")
  end
end
