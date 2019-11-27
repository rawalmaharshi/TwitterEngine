defmodule Proj4.TwitterServer do
    use GenServer
    @me __MODULE__

    def start_link(arg) do
        create_tables()
        GenServer.start_link(@me, arg, name: @me)
    end

    def init(init_state) do
        {:ok, init_state}
    end

    def create_tables do
        :ets.new(:user, [:set, :public, :named_table])# username, password, subscribers , subscribed to, tweet list, online status;
        :ets.new(:hashtags, [:set, :public, :named_table]) # tag, tweets
    end

    def handle_call({:register, username , password}, _from, state) do
        # Add the user in the user table which is stored in the server process
        #The other parameters to add to the user table would be given in the request
        # username = "hello@user"
        # password = "world"
        {:reply, add_newuser(username, password), state}
    end

    def handle_call({:login, username, password}, _from, state) do
        {:reply, authenticate(username, password), state}
    end

    def handle_call({:logout, username}, _from, state) do
        {:reply, logout(username), state}        
    end

    def logout(username) do
        case :ets.lookup(:user, username) do
        [{u, p, s1, s2, t,  onlinestatus}] ->
            if onlinestatus do
                :ets.insert(:user, {u, p, s1, s2, t, false})
                {:ok, "Logged out successfully!!"}
            else
                {:error , "!!!!you are not logged in.!!!!"}
            end
        [] ->
            {:error, "User not registered"}
        end
    end

    def handle_call({:delete_account, username, password}, _from ,state) do
        {:reply, delete_account(username,password),state}
    end
    
    def delete_account(username,p) do
        case :ets.lookup(:user, username) do
            [{username, password, _ , following_list, _ , onlinestatus}] -> 
                if onlinestatus == true do
                    if password == p do
                        Enum.each(following_list, fn(x) -> 
                            unsubscribe_user(username, x)
                        end)
                        [{_ , _, followers_list , _, _, _}] = :ets.lookup(:user, username)
                        Enum.each(followers_list, fn(x) -> 
                            unsubscribe_user(x, username)
                        end)
                        :ets.delete(:user, username)
                        {:ok, "!!!!!!!!Account has been deleted successfully!!!!!!!. We will miss you"}
                    else
                        {:error, "You have entered a wrong password. Try again."}                       
                    end
                else
                    {:error, "You are logged out. please login first"}
                end                
            [] -> {:error, "Invalid user.User is not registered"}
        end
    end


    #work from here
    def handle_cast({:send_tweet, username, tweet}, state) do
        #Add the tweets by the user in the tweets table that looks like
        # UserName, ['hi', 'bye']    --> primary key is username(looked up using that), then there is a list of tweets
        case isLoggedin(username) do
            {:ok, status} ->
                if status do
                    #adding the tweet on the tweeter handle of the user
                    [{username, password , subscriber , subscribing , tweets_list, onlinestatus}] = :ets.lookup(:user, username)
                    if !Enum.member?(tweets_list, tweet) do
                        :ets.insert(:user, {username, password , subscriber , subscribing ,[tweet | tweets_list] , onlinestatus})
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
                            [{x, password2 , subscriber2 , subscribing2 , tweets_list2, onlinestatus2}] ->
                                if !Enum.member?(tweets_list, tweet) do                
                                    :ets.insert(:user, {x,  password2 , subscriber2 , subscribing2 ,[tweet | tweets_list2], onlinestatus2})
                                end
                            [] -> 
                                IO.puts "User #{x} doesn't exist. !!!!!You can't tag this user!!!"
                        end
                    end)
                    IO.puts ("Tweet sent!")
                else
                    IO.puts "Please login first."
                end
            {:error, message} ->
                IO.puts(message)            
        end
        {:noreply, state}#maharshi tell me what to return on this line.
    end       

    def handle_call({:unsubscribe_user, unsubscriber, subscribed_to}, _from, state) do
        {:reply, unsubscribe_user( unsubscriber, subscribed_to), state}
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

    def subscribe_hashtag( subscriber, hashtag) do
        case :ets.lookup(:user, subscriber) do
            [{subscriber, password1 , subscribers_list , subscribed_list, tweets_list , onlinestatus}] ->
                if(onlinestatus == true) do
                    case :ets.lookup(:hashtags, hashtag) do
                        [{hashtag, tweets_list2}] ->
                            if !Enum.member?(tweets_list2, hashtag) do 
                                :ets.insert(:user, {subscriber,  password1 , subscribers_list ,[hashtag | subscribed_list], tweets_list , onlinestatus})
                                {:ok, "#{subscriber} have successfully subscribed to #{hashtag}"}
                            else
                                {:error, "#{subscriber} already subscribed to #{hashtag}"}
                            end
                        [] ->
                            {:error , "#{hashtag} doesn't exist. Sorry"}
                    end
                else
                    {:error , "!!!!!You have to login first to subscribe.!!!!!"}
                end
            [] ->
                {:error , "thier is no subscriber exist  by #{subscriber} name. Request denied"}
        end
    end

    def subscribe_user( subscriber, subscribed_to) do
        case :ets.lookup(:user, subscriber) do
            [{subscriber, password1 , subscribers_list , subscribed_list, tweets_list , onlinestatus}] ->
                if(onlinestatus == true) do
                    case :ets.lookup(:user, subscribed_to) do
                        [{subscribed_to, password2 , subscribers_list2 , subscribed_list2, tweets_list2 , onlinestatus2}] ->
                            if !Enum.member?(subscribed_list, subscribed_to) do
                                :ets.insert(:user, {subscriber,  password1 , subscribers_list ,[subscribed_to | subscribed_list], tweets_list , onlinestatus})
                                :ets.insert(:user, {subscribed_to,  password2 ,[subscriber | subscribers_list2], subscribed_list2, tweets_list2 , onlinestatus2})
                                {:ok, "#{subscriber} have successfully subscribed to #{subscribed_to}"}
                            else
                                {:error, "#{subscriber} already subscribed to #{subscribed_to}"}
                            end
                        [] ->
                            {:error , "User #{subscribed_to} doesn't exist."}
                    end
                else
                    {:error , "You have to login first to subscribe."}
                end
            [] ->
                {:error , "No subscriber exists  by #{subscriber} name. Request denied"}
        end
    end

    def handle_call({:get_tweets_for_user, username},_from,state) do
        [{_, _, _, following_list ,_ , _}] = :ets.lookup(:user, username)
         temp = Enum.reduce(following_list,[], fn (x, acc) ->
            if Regex.scan(~r/#[á-úÁ-Úä-üÄ-Üa-zA-Z0-9_]+/, x) != [] do
                [ get_hashtag_posts(x) | acc]
            else
                [ get_tweets(x) | acc] 
            end
        end)
        temp = List.flatten(temp) |> Enum.uniq
        {:reply ,temp , state}
    end

    def handle_call({:get_user_tweets, username},_from,state) do
        {:reply, get_tweets(username) ,state}
    end

    def get_tweets(username) do
        case :ets.lookup(:user,username) do
            [{_, _, _, _ , tweet_list , _}] -> tweet_list
            [] -> []
        end
    end

    def get_hashtag_posts(hashtag) do
        case :ets.lookup(:hashtags,hashtag) do
            [{ _ , tweet_list }] -> tweet_list
            [] -> []
        end
    end

    def unsubscribe_user( unsubscriber, subscribed_to) do
        case :ets.lookup(:user, unsubscriber) do
            [{unsubscriber, password1 , subscribers_list , subscribed_list, tweets_list , onlinestatus}] ->
                if(onlinestatus == true) do
                    case :ets.lookup(:user, subscribed_to) do
                        [{subscribed_to, password2 , subscribers_list2 , subscribed_list2, tweets_list2 , onlinestatus2}] ->
                            if Enum.member?(subscribed_list, subscribed_to) do
                                :ets.insert(:user, {unsubscriber,  password1 , subscribers_list ,List.delete(subscribed_list,subscribed_to), tweets_list , onlinestatus})
                                :ets.insert(:user, {subscribed_to,  password2 ,List.delete(subscribers_list2, unsubscriber), subscribed_list2, tweets_list2 , onlinestatus2})
                                {:ok, "#{unsubscriber} have successfully unsubscribed from #{subscribed_to}"}
                            else
                                {:error, "#{unsubscriber} already unsubscribed from #{subscribed_to}"}
                            end                            
                        [] ->
                            {:error , "#{subscribed_to} doesn't exist."}
                    end
                else
                    {:error , "You have to login first to subscribe."}
                end
            [] ->
                {:error , "No subscriber exists  by #{unsubscriber} name."}
        end
    end

    def unsubscribe_hashtag( unsubscriber, hashtag) do
        case :ets.lookup(:user, unsubscriber) do
            [{unsubscriber, password1 , subscribers_list , subscribed_list, tweets_list , onlinestatus}] ->
                if(onlinestatus == true) do
                    case :ets.lookup(:hashtags, hashtag) do
                        [{hashtag, tweets_list2}] ->
                            :ets.insert(:user, {unsubscriber,  password1 , subscribers_list ,List.delete(subscribed_list,hashtag), tweets_list , onlinestatus})
                            {:ok, "#{unsubscriber} have successfully unsubscribed to #{hashtag}"}
                            
                        [] ->
                            {:error , " #{hashtag} doesn't exist. Sorry"}
                    end
                else
                    {:error , "you have to login first to subscribe."}
                end
            [] ->
                {:error , "thier is no subscriber exist  by #{unsubscriber} name. Request denied"}
        end
    end

    def unsubscribe_hashtag( unsubscriber, hashtag) do
        case :ets.lookup(:user, unsubscriber) do
            [{unsubscriber, password1 , subscribers_list , subscribed_list, tweets_list , onlinestatus}] ->
                if(onlinestatus == true) do
                    case :ets.lookup(:hashtags, hashtag) do
                        [{hashtag, tweets_list2}] ->
                            if Enum.member?(subscribed_list, hashtag) do
                                :ets.insert(:user, {unsubscriber,  password1 , subscribers_list ,List.delete(subscribed_list,hashtag), tweets_list , onlinestatus})
                                {:ok, "#{unsubscriber} have successfully unsubscribed to #{hashtag}"}
                            else
                                {:error, "#{unsubscriber} already unsubscribed to #{hashtag}"}
                            end
                        [] ->
                            {:error , " #{hashtag} doesn't exist. Sorry"}
                    end
                else
                    {:error , "you have to login first to subscribe."}
                end
            [] ->
                {:error , "thier is no subscriber exist  by #{unsubscriber} name. Request denied"}
        end
    end
    
    def handle_call({:retweet}, _from, state) do
        # No change in the tables 
        # Look for the subscriber table, send a request to all subscribers asking them to :retweet
        # The user also is a subscriber in someone else's table hence, he would also get a retweeet option before he sends a retweet option to other users

        {:reply, state, state}
    end

    def add_newuser(userName, password) do        
        if checkuser(userName) do
            {:error, "This user already exists. Try another username."}
        else
            :ets.insert_new(:user, {userName, password, [], [], [], false})
            {:ok, "New user #{userName} successfully added"}
        end
    end

    def checkuser(username) do
        case :ets.lookup(:user, username) do
            [{_, _, _, _, _, _}] -> true
            [] -> false
        end
    end

    def authenticate(username, password) do
        case :ets.lookup(:user, username) do
            [{username, p, s1 , s2, t, onlinestatus}] -> 
                if onlinestatus == false do
                    if p == password do
                        :ets.insert(:user, {username, p, s1 , s2, t, true})
                        {:ok, "Logged in successfully!!"}    
                    else
                        {:error, "You have entered a wrong password. Try again!"}                       
                    end
                else
                    {:error, "You are already logged in"}
                end                
            [] -> {:error, "User is not registered. Please register the user."}
        end
    end

    def isLoggedin(username) do
        case :ets.lookup(:user, username) do
            [{_, _, _, _, _, x}] -> {:ok, x}
            [] -> {:error, "Register first to send the tweets"}
        end        
    end  
end