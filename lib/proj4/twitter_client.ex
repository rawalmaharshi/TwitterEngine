defmodule Proj4.TwitterClient do
    use GenServer
    @me __MODULE__

    def start_link(arg) do
        GenServer.start_link(@me, arg)
    end

    def init(init_state) do
        pid = self()
        {_ , name} = Map.fetch(init_state, :name)
        currentState = Map.put_new(init_state, :pid, pid)
        GenServer.cast(Proj4.TwitterServer, {:add_node_name_to_global_list, pid, name})
        {:ok, currentState}
    end

    def terminate(_reason, state) do
        IO.puts "***** Exiting Twitter Client GenServer *****"
        IO.inspect state
    end

    def handle_cast({:recieve_tweet}) do
        # Here the user recieves the tweet from the server process and outputs it onto the screen
    end

    def register_user(username, password, client_pid, server_pid) do 
        GenServer.call(Proj4.TwitterServer, {:register, username, password, client_pid})
    end

    def login_user(username, password, client_pid, server_pid) do
        GenServer.call(server_pid, {:login, username, password, client_pid})
    end

    def logout_user(username, client_pid, server_pid) do
        GenServer.call(server_pid, {:logout, username, client_pid})
    end

    def subscribe_to_user(user1, user2, server_pid) do
        GenServer.call(server_pid, {:subscribe_user, user1, user2})
    end

    def unsubscribe_from_user(user1, user2, server_pid) do
        GenServer.call(server_pid, {:unsubscribe_user, user1, user2})
    end

    def delete_user(username, password, server_pid) do
        GenServer.call(server_pid, {:delete_account, username, password})
    end
    
    def send_tweet(username, tweet, _client_pid, server_pid) do
        GenServer.call(server_pid, {:send_tweet, username, tweet})
    end

    def get_tweets_for_user(username, client_pid, server_pid) do
        GenServer.call(server_pid, {:get_tweets_for_user, username})
    end
end