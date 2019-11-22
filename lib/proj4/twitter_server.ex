def module Proj4.TwitterServer do
    use GenServer
    @me __MODULE__

    def start_link(arg) do
        create_tables
        GenServer.start_link(@me, arg, name: @me)
    end

    def init(init_state) do
        {:ok, init_state}
    end

    def create_tables do
        :ets.new(:user, [:set, :public, :named_table])
        :ets.new(:tweets, [:set, :public, :named_table])
        :ets.new(:hashtags, [:set, :public, :named_table])
        :ets.new(:mentions, [:set, :public, :named_table])
    end

    def handle_call({:register_user}, state) do
        # Add the user in the user table which is stored in the server process
        #The other parameters to add to the user table would be given in the request
        {:reply, add_newuser(username, password), state}
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

    def handle_call({:store_tweet}, state) do
        #Add the tweets by the user in the tweets table that looks like
        # UserName, ['hi', 'bye']    --> primary key is username(looked up using that), then there is a list of tweets
        {:reply, new_state}
    end

    def handle_call({:subscribe}, state) do
        #In the table of the user, add two entries: 
        # Subscriber: the user which is subscribed, append the subscribing user
        # subscribed: the user which is subscribing, add the subscribed user

        {:reply, new_state}
    end

    def handle_call({:retweet}, state) do
        # No change in the tables 
        # Look for the subscriber table, send a request to all subscribers asking them to :retweet
        # The user also is a subscriber in someone else's table hence, he would also get a retweeet option before he sends a retweet option to other users

        {:reply, new_state}
    end
end