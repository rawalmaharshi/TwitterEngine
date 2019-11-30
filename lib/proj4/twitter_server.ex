defmodule Proj4.TwitterServer do
    use GenServer
    @me __MODULE__

    def start_link(arg) do
        GenServer.start_link(@me, arg, name: @me)
    end

    def init(init_state) do
        pid = self()
        create_tables()
        new_state = Map.put_new(init_state, :server_pid, pid)
        {:ok, new_state}
    end

    def create_tables do
        :ets.new(:user, [:set, :public, :named_table])# username, password, subscribers , subscribed to, tweet list, online status;
        :ets.new(:hashtags, [:set, :public, :named_table]) # tag, tweets
    end

    def handle_cast({:add_node_name_to_global_list, pid, name}, state) do
        {_ , clientProcesses} = Map.fetch(state , :clientProcesses)
        clientProcesses = Map.put(clientProcesses , name , pid)
        state = Map.put(state , :clientProcesses, clientProcesses)
        {:noreply, state}
    end

    def handle_call({:register, username , password, user_pid}, _from, state) do
        {:reply, add_newuser(username, password, user_pid), state}
    end

    def handle_call({:login, username, password, client_pid}, _from, state) do
        {:reply, authenticate(username, password, client_pid), state}
    end

    def handle_call({:logout, username, client_pid}, _from, state) do
        {:reply, logout(username, client_pid), state}        
    end

    def handle_call({:delete_account, username, password}, _from ,state) do
        {:reply, delete_account(username,password),state}
    end

    def handle_call({:send_tweet, username, tweet}, _from, state) do
        {:reply, send_tweet(username, tweet), state}
    end

    def handle_call({:unsubscribe_user, unsubscriber, subscribed_to}, _from, state) do
        {:reply, unsubscribe_user(unsubscriber, subscribed_to), state}
    end

    def handle_call({:subscribe_user, subscriber, subscribed_to}, _from, state) do
        {:reply, subscribe_user(subscriber, subscribed_to), state}
    end

    def handle_call({:subscribe_hashtag, subscriber, hashtag}, _from, state) do
        {:reply, subscribe_hashtag(subscriber, hashtag), state}
    end

    def handle_call({:unsubscribe_hashtag, unsubscriber, hashtag}, _from, state) do
        {:reply, unsubscribe_hashtag(unsubscriber, hashtag), state}
    end

    def handle_call({:get}, _from, current_state) do
        {:reply, current_state, current_state}
    end

    def handle_call({:get_tweets_for_user, username}, _from ,state) do   
        {:reply ,get_tweets_for_user_wall(username) , state}
    end

    def handle_call({:get_user_tweets, username},_from,state) do
        {:reply, get_tweets(username) ,state}
    end

    def handle_call({:retweet, user}, _from, state) do
        {:reply, get_tweets(user) ,state}
    end

    def handle_call({:get_subsribers_count, user}, _from, state) do
        {:reply, get_subs_count(user), state}
    end

    def get_subs_count(user) do
        [{_, _, subscribers, _, _, _, _}] = :ets.lookup(:user, user)
        subsCount = length(subscribers)
        subsCount
    end

    def logout(username, _client_pid) do
        case :ets.lookup(:user, username) do
        [{u, p, s1, s2, t,  onlinestatus, client_pid}] ->
            if onlinestatus do
                :ets.insert(:user, {u, p, s1, s2, t, false, client_pid})
                IO.puts "Logged out successfully!!"
                {:ok, "Logged out successfully!!"}
            else
                IO.puts "!!!!you are not logged in.!!!!"
                {:error , "!!!!you are not logged in.!!!!"}
            end
        [] ->
            IO.puts "User not registered"
            {:error, "User not registered"}
        end
    end
    
    def delete_account(username,p) do
        case :ets.lookup(:user, username) do
            [{username, password, _ , following_list, _ , onlinestatus, _}] -> 
                if onlinestatus == true do
                    if password == p do
                        Enum.each(following_list, fn(x) -> 
                            unsubscribe_user(username, x)
                        end)
                        [{_ , _, followers_list2 , _, _, _, _}] = :ets.lookup(:user, username)
                        Enum.each(followers_list2, fn(x) -> 
                            unsubscribe_user(x, username)
                        end)
                        :ets.delete(:user, username)
                        IO.puts "!!!!!!!!Account has been deleted successfully!!!!!!!. We will miss you"
                        {:ok, "!!!!!!!!Account has been deleted successfully!!!!!!!. We will miss you"}
                    else
                        IO.puts "You have entered a wrong password. Try again."
                        {:error, "You have entered a wrong password. Try again."}                       
                    end
                else
                    IO.puts "You are logged out. please login first"
                    {:error, "You are logged out. please login first"}
                end                
            [] -> 
                IO.puts "Invalid user. User is not registered"
                {:error, "Invalid user. User is not registered"}
        end
    end       

    def send_tweet(username, tweet) do
        case isLoggedin(username) do
            {:ok, status} ->
                if status do
                    #adding the tweet on the tweeter handle of the user
                    [{username, password , subscriber , subscribing , tweets_list, onlinestatus, pid}] = :ets.lookup(:user, username)
                    if !Enum.member?(tweets_list, tweet) do
                        :ets.insert(:user, {username, password , subscriber , subscribing ,[tweet | tweets_list] , onlinestatus, pid})
                    end
                    #adding the hastags in the hashtable
                    allhashtags = Regex.scan(~r/#[á-úÁ-Úä-üÄ-Üa-zA-Z0-9_]+/, tweet)
                    Enum.each( allhashtags, fn([x]) ->
                        case :ets.lookup(:hashtags, x) do
                            [{x, tweets_list}] ->
                                if !Enum.member?(tweets_list, tweet) do                
                                    :ets.insert(:hashtags, {x, [tweet | tweets_list]})
                                end
                            [] -> 
                                :ets.insert_new(:hashtags, {x, [tweet]})
                        end
                    end)
                    #adding the tweets on the wall of tagged users
                    allusernames=  Regex.scan(~r/[á-úÁ-Úä-üÄ-Üa-zA-Z0-9@._]+@user+/, tweet)
                    Enum.each(allusernames, fn([x]) ->
                        case :ets.lookup(:user, x) do
                            [{x, password2 , subscriber2 , subscribing2 , tweets_list2, onlinestatus2, pid}] ->
                                if !Enum.member?(tweets_list, tweet) do                
                                    :ets.insert(:user, {x,  password2 , subscriber2 , subscribing2 ,[tweet | tweets_list2], onlinestatus2, pid})
                                end
                            [] -> 
                                IO.puts "User #{x} doesn't exist. !!!!!You can't tag this user!!!"
                        end
                    end)
                    IO.puts ("Tweet sent by #{username}")
                    _message = {:ok, "Tweet sent!"}
                else
                    IO.puts "Please login first."
                    _message = {:error, "Please login first"}
                end
            {:error, message} ->
                {:error, message}            
        end
    end

    def getServerState() do
        GenServer.call(@me, {:get})
    end

    def subscribe_hashtag( subscriber, hashtag) do
        case :ets.lookup(:user, subscriber) do
            [{subscriber, password1 , subscribers_list , subscribed_list, tweets_list , onlinestatus}] ->
                if(onlinestatus == true) do
                    case :ets.lookup(:hashtags, hashtag) do
                        [{hashtag, tweets_list2}] ->
                            if !Enum.member?(tweets_list2, hashtag) do 
                                :ets.insert(:user, {subscriber,  password1 , subscribers_list ,[hashtag | subscribed_list], tweets_list , onlinestatus})
                                IO.puts "#{subscriber} have successfully subscribed to #{hashtag}"
                                {:ok, "#{subscriber} have successfully subscribed to #{hashtag}"}
                            else
                                IO.puts "#{subscriber} already subscribed to #{hashtag}"
                                {:error, "#{subscriber} already subscribed to #{hashtag}"}
                            end
                        [] ->
                            IO.puts "#{hashtag} doesn't exist. Sorry"
                            {:error , "#{hashtag} doesn't exist. Sorry"}
                    end
                else
                    IO.puts "!!!!!You have to login first to subscribe.!!!!!"
                    {:error , "!!!!!You have to login first to subscribe.!!!!!"}
                end
            [] ->
                IO.puts "There is no subscriber exist  by #{subscriber} name. Request denied"
                {:error , "There is no subscriber exist  by #{subscriber} name. Request denied"}
        end
    end

    def subscribe_user( subscriber, subscribed_to) do
        case :ets.lookup(:user, subscriber) do
            [{subscriber, password1 , subscribers_list , subscribed_list, tweets_list , onlinestatus, pid1}] ->
                if(onlinestatus == true) do
                    case :ets.lookup(:user, subscribed_to) do
                        [{subscribed_to, password2 , subscribers_list2 , subscribed_list2, tweets_list2 , onlinestatus2, pid2}] ->
                            if !Enum.member?(subscribed_list, subscribed_to) do
                                :ets.insert(:user, {subscriber,  password1 , subscribers_list ,[subscribed_to | subscribed_list], tweets_list , onlinestatus, pid1})
                                :ets.insert(:user, {subscribed_to,  password2 ,[subscriber | subscribers_list2], subscribed_list2, tweets_list2 , onlinestatus2, pid2})
                                IO.puts "#{subscriber} have successfully subscribed to #{subscribed_to}"
                                {:ok, "#{subscriber} have successfully subscribed to #{subscribed_to}"}
                            else
                                IO.puts "#{subscriber} already subscribed to #{subscribed_to}"
                                {:error, "#{subscriber} already subscribed to #{subscribed_to}"}
                            end
                        [] ->
                            IO.puts "User #{subscribed_to} doesn't exist."
                            {:error , "User #{subscribed_to} doesn't exist."}
                    end
                else
                    IO.puts "You have to login first to subscribe."
                    {:error , "You have to login first to subscribe."}
                end
            [] ->
                IO.puts "No subscriber exists  by #{subscriber} name. Request denied"
                {:error , "No subscriber exists  by #{subscriber} name. Request denied"}
        end
    end

    def get_tweets_for_user_wall(username) do
        [{_, _, _, following_list ,_ , _, _}] = :ets.lookup(:user, username)
         temp = Enum.reduce(following_list,[], fn (x, acc) ->
            if Regex.scan(~r/#[á-úÁ-Úä-üÄ-Üa-zA-Z0-9_]+/, x) != [] do
                [ get_hashtag_posts(x) | acc]
            else
                [ get_tweets(x) | acc] 
            end
        end)
        temp = List.flatten(temp) |> Enum.uniq
        temp
    end

    def get_tweets(username) do
        case :ets.lookup(:user,username) do
            [{_, _, _, _ , tweet_list , _, _}] -> tweet_list
            [] -> []
        end
    end

    def get_hashtag_posts(hashtag) do
        case :ets.lookup(:hashtags,hashtag) do
            [{ _ , tweet_list }] -> tweet_list
            [] -> []
        end
    end

    def unsubscribe_user(unsubscriber, subscribed_to) do
        case :ets.lookup(:user, unsubscriber) do
            [{unsubscriber, password1 , subscribers_list , subscribed_list, tweets_list , onlinestatus, pid1}] ->
                if(onlinestatus == true) do
                    case :ets.lookup(:user, subscribed_to) do
                        [{subscribed_to, password2 , subscribers_list2 , subscribed_list2, tweets_list2 , onlinestatus2, pid2}] ->
                            if Enum.member?(subscribed_list, subscribed_to) do
                                :ets.insert(:user, {unsubscriber,  password1 , subscribers_list ,List.delete(subscribed_list,subscribed_to), tweets_list , onlinestatus, pid1})
                                :ets.insert(:user, {subscribed_to,  password2 ,List.delete(subscribers_list2, unsubscriber), subscribed_list2, tweets_list2 , onlinestatus2, pid2})
                                IO.puts "#{unsubscriber} have successfully unsubscribed from #{subscribed_to}"
                                {:ok, "#{unsubscriber} have successfully unsubscribed from #{subscribed_to}"}
                            else
                                IO.puts "#{unsubscriber} already unsubscribed from #{subscribed_to}"
                                {:error, "#{unsubscriber} already unsubscribed from #{subscribed_to}"}
                            end                            
                        [] ->
                            IO.puts "#{subscribed_to} doesn't exist."
                            {:error , "#{subscribed_to} doesn't exist."}
                    end
                else
                    IO.puts "You have to login first to subscribe."
                    {:error , "You have to login first to subscribe."}
                end
            [] ->
                IO.puts "No subscriber exists  by #{unsubscriber} name."
                {:error , "No subscriber exists  by #{unsubscriber} name."}
        end
    end

    def unsubscribe_hashtag( unsubscriber, hashtag) do
        case :ets.lookup(:user, unsubscriber) do
            [{unsubscriber, password1 , subscribers_list , subscribed_list, tweets_list , onlinestatus}] ->
                if(onlinestatus == true) do
                    case :ets.lookup(:hashtags, hashtag) do
                        [{hashtag, _tweets_list2}] ->
                            if Enum.member?(subscribed_list, hashtag) do
                                :ets.insert(:user, {unsubscriber,  password1 , subscribers_list ,List.delete(subscribed_list,hashtag), tweets_list , onlinestatus})
                                IO.puts "#{unsubscriber} have successfully unsubscribed to #{hashtag}"
                                {:ok, "#{unsubscriber} have successfully unsubscribed to #{hashtag}"}
                            else
                                IO.puts "#{unsubscriber} already unsubscribed to #{hashtag}"
                                {:error, "#{unsubscriber} already unsubscribed to #{hashtag}"}
                            end
                        [] ->
                            IO.puts "#{hashtag} doesn't exist. Sorry"
                            {:error , "#{hashtag} doesn't exist. Sorry"}
                    end
                else
                    IO.puts "You have to login first to subscribe."
                    {:error , "You have to login first to subscribe."}
                end
            [] ->
                IO.puts "There is no subscriber by #{unsubscriber} name"
                {:error , "There is no subscriber by #{unsubscriber} name"}
        end
    end

    def add_newuser(userName, password, user_pid) do        
        if checkuser(userName) do
            IO.puts "This user already exists."
            {:error, "This user already exists."}
        else
            :ets.insert_new(:user, {userName, password, [], [], [], false, user_pid})
            IO.puts "New user #{userName} successfully added"
            {:ok, "New user #{userName} successfully added"}
        end
    end

    def checkuser(username) do
        case :ets.lookup(:user, username) do
            [{_, _, _, _, _, _, _}] -> true
            [] -> false
        end
    end

    def authenticate(username, password, _client_pid) do
        case :ets.lookup(:user, username) do
            [{username, p, s1 , s2, t, onlinestatus, client_pid}] -> 
                if onlinestatus == false do
                    if p == password do
                        :ets.insert(:user, {username, p, s1 , s2, t, true, client_pid})
                        IO.puts "Logged in successfully!!"
                        {:ok, "Logged in successfully!!"}    
                    else
                        IO.puts "You have entered a wrong password. Try again!"
                        {:error, "You have entered a wrong password. Try again!"}                       
                    end
                else
                    IO.puts "You are already logged in"
                    {:error, "You are already logged in"}
                end                
            [] -> 
                IO.puts "User is not registered. Please register the user."
                {:error, "User is not registered. Please register the user."}
        end
    end

    def isLoggedin(username) do
        case :ets.lookup(:user, username) do
            [{_, _, _, _, _, x, _pid}] -> {:ok, x}
            [] ->
                IO.puts "Register first to send the tweets"
                {:error, "Register first to send the tweets"}
        end        
    end  

    def get() do
        GenServer.call(@me, {:get})
    end
end