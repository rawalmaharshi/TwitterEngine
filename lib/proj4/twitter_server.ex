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
        :ets.new(:user, [:set, :public, :named_table])#
        :ets.new(:tweets, [:set, :public, :named_table])
        :ets.new(:hashtags, [:set, :public, :named_table])
        :ets.new(:mentions, [:set, :public, :named_table])
    end

    def handle_call({:register}, _from, state) do
        # Add the user in the user table which is stored in the server process
        #The other parameters to add to the user table would be given in the request
        username = "hello"
        password = "world"
        {:reply, add_newuser(username, password), state}
    end

    def handle_call({:login, username, password}, _from, state) do
        #session_Id = :crypto.hash(:sha256, username.to) |> Base.encode16

        {:reply, authenticate(username, password), state}
    end

    def handle_call({:logout, _username}, _from, state) do
        {:reply, "logout(username)", state}        
    end

    # def logout(username) do
    #     cond :ets.lookup(:user, username) do
    #     [{u, p, s1, s2, t, state}] ->
    #         :ets.insert(:user, {u, p, s1, s2, t, false})
    #         {:ok, "Logged out successfully!!" }
    #     [] ->
    #         {:error, "user not registered"}
    #     end
    # end
    #work from here
    def handle_cast({:send_tweet, username, tweet}, state) do
        #Add the tweets by the user in the tweets table that looks like
        # UserName, ['hi', 'bye']    --> primary key is username(looked up using that), then there is a list of tweets
        case isLoggedin(username) do
            {:ok, status} ->
                if status do
                    #adding the tweet on the tweeter handle of the user
                    [{username, _, _, _, tweets_list, _}] = :ets.lookup(:user, username)
                    :ets.insert(:user, {username, [tweet | tweets_list]})
                    #adding the hastags in the hashtable
                    allhashtags = Regex.scan(~r/\B#[a-zA-Z0-9_]+/, tweet)
                    Enum.each( allhashtags, fn(x) ->
                        case :ets.lookup(:hashtags, x) do
                            [{x, tweets_list}] ->                
                                :ets.insert(:hashtags, {x, [tweet | tweets_list]})
                            [] -> :ets.insert_new(:hashtags, {x, [tweet]})
                        end
                    end)
                    #adding the tweets on the wall of tagged users
                    allusernames=  Regex.scan(~r/\B@user[a-zA-Z0-9@._]+/, tweet)
                    Enum.each( allusernames, fn(x) ->
                        case :ets.lookup(:user, x) do
                            [{x, _, _, _, tweets_list, _}] ->                
                                :ets.insert(:user, {x, [tweet | tweets_list]})
                            [] -> :ets.insert_new(:user, {x, [tweet]})
                        end
                    end)
                    
                else
                    IO.puts "Please login first."
                end
            {:error, message} ->
                IO.puts(message)            
        end
        {:noreply, state}#maharshi tell me what to return on this line.
    end       

    def handle_call({:subscribe}, _from, state) do
        #In the table of the user, add two entries: 
        # Subscriber: the user which is subscribed, append the subscribing user
        # subscribed: the user which is subscribing, add the subscribed user

        {:reply, state, state}
    end



    def handle_cast({:retweet}, _from, state) do
        # No change in the tables 
        # Look for the subscriber table, send a request to all subscribers asking them to :retweet
        # The user also is a subscriber in someone else's table hence, he would also get a retweeet option before he sends a retweet option to other users

        {:reply, state, state}
    end

    def add_newuser(userName, password) do        
        if checkuser(userName) do
            {:error, "This user is already exist. Try another username"}
        else
            :ets.insert_new(:user, {userName, password, [], [], [], false})
            {:ok, "new user #{userName} successfully added "}
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
                    if _pass = password do
                        :ets.insert(:user, {username, p, s1 , s2, t, true})
                        {:ok, "Logged in successfully!!"}    
                    else
                        {:error, "You have entered a wron password. Try again."}                       
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