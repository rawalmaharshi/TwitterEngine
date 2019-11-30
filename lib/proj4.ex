defmodule Proj4 do
  
  def main(args \\ []) do
    startProject(args)
  end

  def startProject(args) do
    # :observer.start
    [numUsers, numTweets, runType] = args
    if runType == nil do
      IO.puts "Please enter the third argument to run the bonus part of this project"
      System.halt(0)
    end

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
    defaultListOfOperations = ["login", "send_tweets", "subscribe", "unsubscribe", "logout"]

    # Register user and login in to the system as well
    :ets.new(:tweets_count, [:set, :protected, :named_table])
    Enum.each(clientProcesses, fn {user_name, user_pid} -> 
      password = Enum.random(defaultPasswords)
      Proj4.TwitterClient.register_user(user_name, password, user_pid, server_pid)
      Proj4.TwitterClient.login_user(user_name, password, user_pid, server_pid)
      :ets.insert(:tweets_count, {user_name, 0, 0})
    end)

    # start time of tweet sending mechanism
    start_time = System.monotonic_time(:millisecond)

    cond do
      runType == "normal" ->
        # All the users send tweets (numTweets times) that gets logged into the server (Not a part of bonus)
        Enum.each(user_names, fn user -> 
          Enum.each(1..numTweets, fn _tweetsCount -> 
            randomTweetMessage = Enum.random(defaultTweets) <> " " <> Enum.random(defaultHashtags)
            #send tweets
            task = Task.async(fn -> 
            Proj4.TwitterClient.send_tweet(user, randomTweetMessage, Proj4.TwitterClient.get_client_pid_from_username(user), server_pid)
            end)
        Task.await(task, :infinity)
          end)
        end)
        IO.puts("Time after #{numUsers} users have sent #{numTweets} tweets: " <> to_string(System.monotonic_time(:millisecond) - start_time) <> " milliseconds")

      runType == "zipf" ->
        #Bonus Part
        #Assign subscribers according to Zipf

        zConstant = zipf_constant(Kernel.map_size(clientProcesses))
        Enum.each(1..numUsers, fn user -> 
          zProb = zipf_prob(zConstant, user, numUsers)
          currentUser = Enum.at(user_names, user - 1)
          Enum.each(0..(zProb - 1), fn _a -> 
            other_user = Enum.random(Enum.filter(user_names, fn u -> u != currentUser end))
            #Assign subscribers to user
            Proj4.TwitterClient.subscribe_to_user(other_user, currentUser, server_pid)
          end)
        end)

        #Send randomized tweets according to the number of subscribers
        Enum.each(user_names, fn user ->
          #No. of tweets is a function of no. of subscribers of a user
          numTweetsForCurrentUser = 2 * Proj4.TwitterClient.get_subsribers_count(user, server_pid)
          Enum.each(1..numTweetsForCurrentUser, fn _tweetsCount -> 
            randomTweetMessage = Enum.random(defaultTweets) <> " " <> Enum.random(defaultHashtags)
            #send tweets
            task = Task.async(fn -> 
              Proj4.TwitterClient.send_tweet(user, randomTweetMessage, Proj4.TwitterClient.get_client_pid_from_username(user), server_pid)
              Proj4.TwitterClient.retweet(user, server_pid)
            end)
            Task.await(task, :infinity)
          end)
        end)
        IO.puts("Time taken to send randomized tweets according to zipf distribution: " <> to_string(System.monotonic_time(:millisecond) - start_time) <> " milliseconds")

        runType == "stimulate" ->
          simulate(defaultListOfOperations, user_names, defaultTweets, defaultHashtags, defaultPasswords, server_pid)
          IO.puts("Time taken to complete simulation: " <> to_string(System.monotonic_time(:millisecond) - start_time) <> " milliseconds")

        true ->
          IO.puts "Wrong Argument Entered"
          System.halt(0);
    end
  end

  defp simulate(defaultListOfOperations, user_names, defaultTweets, defaultHashtags, defaultPasswords, server_pid) do
    cond do
      Enum.random(defaultListOfOperations) == "login" ->
        currentUser = Enum.random(user_names)
        Proj4.TwitterClient.login_user(currentUser, Enum.random(defaultPasswords), Proj4.TwitterClient.get_client_pid_from_username(currentUser), server_pid)
        
      Enum.random(defaultListOfOperations) == "send_tweets" -> 
        currentUser = Enum.random(user_names)
        randomTweetMessage = Enum.random(defaultTweets) <> " " <> Enum.random(defaultHashtags)
        Proj4.TwitterClient.send_tweet(currentUser, randomTweetMessage, Proj4.TwitterClient.get_client_pid_from_username(currentUser), server_pid)
      
      Enum.random(defaultListOfOperations) == "subscribe" ->
        currentUser = Enum.random(user_names)
        other_user = Enum.random(Enum.filter(user_names, fn u -> u != currentUser end))
        Proj4.TwitterClient.subscribe_to_user(currentUser, other_user, server_pid)
      
      Enum.random(defaultListOfOperations) == "unsubscribe" ->
        currentUser = Enum.random(user_names)
        other_user = Enum.random(Enum.filter(user_names, fn u -> u != currentUser end))
        Proj4.TwitterClient.unsubscribe_from_user(currentUser, other_user, server_pid)
      
      Enum.random(defaultListOfOperations) == "logout" ->  
        currentUser = Enum.random(user_names)
        Proj4.TwitterClient.logout_user(currentUser, Proj4.TwitterClient.get_client_pid_from_username(currentUser), server_pid)
      
      true -> 
        IO.puts "Simulation Complete"
        System.halt(0)
    end
    simulate(defaultListOfOperations, user_names, defaultTweets, defaultHashtags, defaultPasswords, server_pid)
  end

  defp zipf_constant(numUsers) do
    numUsers = for n <- 1..numUsers, do: 1/n
    :math.pow(Enum.sum(numUsers), -1)
  end

  defp zipf_prob(constant, userIndex, numUsers) do
    round((constant/userIndex) * numUsers)
  end
end