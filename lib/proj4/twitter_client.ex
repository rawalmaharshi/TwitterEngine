defmodule Proj4.TwitterClient do
    use GenServer
    @me __MODULE__

    def start_link(arg) do
        GenServer.start_link(@me, arg)
    end

    def init(init_state) do
        {:ok, init_state}
    end

    def terminate(_reason, state) do
        IO.puts "***** Exiting Twitter Client GenServer *****"
        IO.inspect state
    end

    def handle_cast({:recieve_tweet}) do
        # Here the user recieves the tweet from the server process and outputs it onto the screen
    end

    def handle_cast({:send_tweet, message}, state) do
        # Here the user sends a tweet request to the server process, server will store its tweet in its table
        # Then the server process will look for this user's subscriber's list; and send another request to all its subsribers to retweet {Those subsribers will actually recieve a tweet first}

    end

    def register_user(username, password, server_pid) do 
        GenServer.call(server_pid, {:register, username, password})
    end

    def login_user(username, password, server_pid) do
        GenServer.call(server_pid, {:login, username, password})
    end

    def logout_user(username, server_pid) do
        GenServer.call(server_pid, {:logout, username})
    end

    def subscribe_to_user(user1, user2, server_pid) do
        GenServer.call(server_pid, {:subscribe_user, user1, user2})
    end

    def unsubscribe_from_user(user1, user2, server_pid) do
        GenServer.call(server_pid, {:unsubscribe_user, user1, user2})
    end

end