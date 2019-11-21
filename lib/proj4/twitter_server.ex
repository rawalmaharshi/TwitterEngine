def module Proj4.TwitterServer do
    use GenServer
    @me __MODULE__

    def start_link(arg) do
        GenServer.start_link(@me, arg, name: @me)
    end

    def init(init_state) do
        {:ok, init_state}
    end

    def handle_cast({:register_user}, state) do
        # Add the user in the user table which is stored in the server process
        #The other parameters to add to the user table would be given in the request
        {:no_reply, new_state}
    end

    def handle_cast({:store_tweet}, state) do
        #Add the tweets by the user in the tweets table that looks like
        # UserName, ['hi', 'bye']    --> primary key is username(looked up using that), then there is a list of tweets
        {:no_reply, new_state}
    end

    def handle_cast({:subscribe}, state) do
        #In the table of the user, add two entries: 
        # Subscriber: the user which is subscribed, append the subscribing user
        # subscribed: the user which is subscribing, add the subscribed user

        {:no_reply, new_state}
    end

    def handle_cast({:retweet}, state) do
        # No change in the tables 
        # Look for the subscriber table, send a request to all subscribers asking them to :retweet
        # The user also is a subscriber in someone else's table hence, he would also get a retweeet option before he sends a retweet option to other users

        {:no_reply, new_state}
    end
end