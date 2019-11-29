defmodule Proj4Test do
  use ExUnit.Case
  doctest Proj4

  setup do
    {:ok, server_pid} = GenServer.start_link(Proj4.TwitterServer, %{clientProcesses: %{} })
    {:ok, server: server_pid}
  end

  @doc """
  1) Register User Test
    i) Register successfully
    ii) Duplicate user error
  """
  test "register user", %{server: pid} do
    #table created when server is started
    assert :ets.whereis(:user) != :undefined

    #add user
    username = "DOS"
    password = "COP5615"

    #Start user process
    {_, client_pid} = GenServer.start_link(Proj4.TwitterClient, %{name: username})
    assert {:ok, "New user #{username} successfully added"} == Proj4.TwitterClient.register_user(username, password, client_pid, pid)

    #check user added
    assert :ets.member(:user, username) == true
  end

  test "don't register duplicate user", %{server: pid} do
    #add user 
    user1 = "DOSDuplicate"
    password = "COP5615"

    #start client 
    {_, client_pid} = GenServer.start_link(Proj4.TwitterClient, %{name: user1})

    #Add first user
    assert {:ok, "New user #{user1} successfully added"} == Proj4.TwitterClient.register_user(user1, password, client_pid, pid)

    #duplicate insertion error
    assert {:error, "This user already exists."} == Proj4.TwitterClient.register_user(user1, password, client_pid, pid) 
  end
  
  @doc """
  2) Login User Test
    i) No user with the user name
    ii) Wrong Password enterered
    iii) Correctly log in
    iv) Already logged in
  """

  test "fail login when user doesn't exist", %{server: pid} do
    username = "DOS@USER2"
    password = "COP5615"

    #start client process
    {_, client_pid} = GenServer.start_link(Proj4.TwitterClient, %{name: username})

    #user not registered error
    assert {:error, "User is not registered. Please register the user."} == Proj4.TwitterClient.login_user(username, password, client_pid, pid)
  end

  test "fail login when wrong password is entered", %{server: pid} do
     #add user
     username = "DOS3"
     password = "COP5615"

     #start client process
     {_, client_pid} = GenServer.start_link(Proj4.TwitterClient, %{name: username})

     assert {:ok, "New user #{username} successfully added"} == Proj4.TwitterClient.register_user(username, password, client_pid, pid)

     assert {:error, "You have entered a wrong password. Try again!"} == Proj4.TwitterClient.login_user(username, "Wrongpassword", client_pid, pid)
  end

  test "login when correct password is entered", %{server: pid} do
    #add user
    username = "DOS4"
    password = "COP5615"

    #start client 
    {_, client_pid} = GenServer.start_link(Proj4.TwitterClient, %{name: username})

    assert {:ok, "New user #{username} successfully added"} == Proj4.TwitterClient.register_user(username, password, client_pid, pid)

    assert {:ok, "Logged in successfully!!"} == Proj4.TwitterClient.login_user(username, password, client_pid, pid)

    [{_, _, _, _, _, loginStatus, _}] = :ets.lookup(:user, username)

    assert loginStatus == true
  end

  test "don't login when already logged in the system", %{server: pid} do
    #add user
    username = "DOS5"
    password = "COP5615"

    #start client 
    {_, client_pid} = GenServer.start_link(Proj4.TwitterClient, %{name: username})

    assert {:ok, "New user #{username} successfully added"} == Proj4.TwitterClient.register_user(username, password, client_pid, pid)

    Proj4.TwitterClient.login_user(username, password, client_pid, pid)
    assert {:error, "You are already logged in"} == Proj4.TwitterClient.login_user(username, password, client_pid, pid)
  end

  @doc """
  3) Logout User Test
    i) No user with the user name
    ii) User not logged in
    iii) Successful log out
  """

  test "Don't perform logout as user is not registered", %{server: pid} do
    username = "DOSNotRegistered"

    #start client 
    {_, client_pid} = GenServer.start_link(Proj4.TwitterClient, %{name: username})

    assert {:error, "User not registered"} == Proj4.TwitterClient.logout_user(username, client_pid, pid)
  end

  test "Can't perform logout as user not logged in", %{server: pid} do
    username = "DOSNotLoggedIn"
    password = "COP5615"

    #start client 
    {_, client_pid} = GenServer.start_link(Proj4.TwitterClient, %{name: username})

    # Register First
    Proj4.TwitterClient.register_user(username, password, client_pid, pid)

    assert {:error, "!!!!you are not logged in.!!!!"} == Proj4.TwitterClient.logout_user(username, client_pid, pid)
  end

  test "Successfully log out", %{server: pid} do
    #add user
    username = "DOS6"
    password = "COP5615"

    #start client 
    {_, client_pid} = GenServer.start_link(Proj4.TwitterClient, %{name: username})

    #Register and login first
    Proj4.TwitterClient.register_user(username, password, client_pid, pid)
    Proj4.TwitterClient.login_user(username, password, client_pid, pid)

    assert {:ok, "Logged out successfully!!"} == Proj4.TwitterClient.logout_user(username, client_pid, pid)

    [{_, _, _, _, _, loginStatus, _}] = :ets.lookup(:user, username)

    assert loginStatus == false
  end


  # # @doc """
  # # 4) Delete User Test
  # #   i) If user exist then delete
  # #   ii) else error user doesn't exist
  # # """

  test "Successfully delete the account", %{server: pid} do
    user1 = "mohit1"
    pass1 = "garg1"
    user2 = "mohit2"
    pass2 = "garg2"
    user3 = "mohit3"
    pass3 = "garg3"

    #start clients 
    {_, client_pid1} = GenServer.start_link(Proj4.TwitterClient, %{name: user1})
    {_, client_pid2} = GenServer.start_link(Proj4.TwitterClient, %{name: user2})
    {_, client_pid3} = GenServer.start_link(Proj4.TwitterClient, %{name: user3})


    #Register first
    Proj4.TwitterClient.register_user(user1, pass1, client_pid1, pid)
    Proj4.TwitterClient.register_user(user2, pass2, client_pid2, pid)
    Proj4.TwitterClient.register_user(user3, pass3, client_pid3, pid)

    #Login first user
    Proj4.TwitterClient.login_user(user1, pass1, client_pid1, pid)
    Proj4.TwitterClient.login_user(user2, pass2, client_pid2, pid)
    Proj4.TwitterClient.login_user(user3, pass3, client_pid3, pid)

    #All three users are subscribing each other
    Proj4.TwitterClient.subscribe_to_user(user1, user2, pid)
    Proj4.TwitterClient.subscribe_to_user(user1, user3, pid)
    Proj4.TwitterClient.subscribe_to_user(user2, user1, pid)
    Proj4.TwitterClient.subscribe_to_user(user2, user3, pid)
    Proj4.TwitterClient.subscribe_to_user(user3, user1, pid)
    Proj4.TwitterClient.subscribe_to_user(user3, user2, pid)
    
    #deleting the account of the existing user
     
     assert {:ok, "!!!!!!!!Account has been deleted successfully!!!!!!!. We will miss you"} = Proj4.TwitterClient.delete_user(user1,pass1,pid)
  end

  test "Account doesn't exist", %{server: pid} do
    user1 = "mohit"
    pass1 = "garg"

    #start clients 
    {_, client_pid1} = GenServer.start_link(Proj4.TwitterClient, %{name: user1})
    
    #deleting the account of the existing user
     
     assert {:error, "Invalid user.User is not registered"} = Proj4.TwitterClient.delete_user(user1,pass1,pid)
  end

  @doc """
  5) Subscribe User Test
    i) Correctly subscribe to another user
    ii) other user not registered/ wrong username
  """

  test "Successfully subscribe to other user", %{server: pid} do
    user1 = "DOS7"
    pass1 = "Hello"
    user2 = "DOS8"
    pass2 = "World"

    #start clients 
    {_, client_pid1} = GenServer.start_link(Proj4.TwitterClient, %{name: user1})
    {_, client_pid2} = GenServer.start_link(Proj4.TwitterClient, %{name: user2})


    #Register first
    Proj4.TwitterClient.register_user(user1, pass1, client_pid1, pid)
    Proj4.TwitterClient.register_user(user2, pass2, client_pid2, pid)

    #Login first user
    assert {:ok, "Logged in successfully!!"} == Proj4.TwitterClient.login_user(user1, pass1, client_pid1, pid)

    #Sucessfully subscribe
    assert {:ok, "#{user1} have successfully subscribed to #{user2}"} == Proj4.TwitterClient.subscribe_to_user(user1, user2, pid)

    #Look for entry in the table {Its get added to the subscribers column in the user table}
    [{_user1, _, _user1Followers, user1Follows, _, _, _pid}] = :ets.lookup(:user, user1)
    assert Enum.member?(user1Follows, user2) == true
  end

  test "Unsuccessful subscribe as other user doesn't exist", %{server: pid} do
    user1 = "DOS9"
    user2 = "DOS10"
    pass1 = "Hello"

    #start clients 
    {_, client_pid1} = GenServer.start_link(Proj4.TwitterClient, %{name: user1})
    {_, _client_pid2} = GenServer.start_link(Proj4.TwitterClient, %{name: user2})

    #Register first
    Proj4.TwitterClient.register_user(user1, pass1, client_pid1, pid)

    #Login first user
    assert {:ok, "Logged in successfully!!"} == Proj4.TwitterClient.login_user(user1, pass1, client_pid1, pid)

    assert {:error, "User #{user2} doesn't exist."} == Proj4.TwitterClient.subscribe_to_user(user1, user2, pid)
  end

   @doc """
  5) Unsubscribe User Test
    i) Correctly unsubscribe from another user
    ii) other user not registered/ wrong username
    iii) User not subscribed
  """

  test "Successfully unsubscribe", %{server: pid} do
    user1 = "DOS11"
    user2 = "DOS12"
    pass1 = "Hello"
    pass2 = "World"

    #start clients 
    {_, client_pid1} = GenServer.start_link(Proj4.TwitterClient, %{name: user1})
    {_, client_pid2} = GenServer.start_link(Proj4.TwitterClient, %{name: user2})

    #Register first
    Proj4.TwitterClient.register_user(user1, pass1, client_pid1, pid)
    Proj4.TwitterClient.register_user(user2, pass2, client_pid2, pid)

    #Login first user
    assert {:ok, "Logged in successfully!!"} == Proj4.TwitterClient.login_user(user1, pass1, client_pid1, pid)

    #Subscribe
    IO.inspect Proj4.TwitterClient.subscribe_to_user(user1, user2, pid)

    #Unsubscribe
    # assert {:ok, "#{user1} have successfully unsubscribed from #{user2}"} == Proj4.TwitterClient.unsubscribe_from_user(user1, user2, pid)
  end

  test "The user entered to unsubscribe is not registered", %{server: pid} do
    user1 = "DOS13"
    user2 = "DOS14"
    pass1 = "Hello"

    #start client
    {_, client_pid1} = GenServer.start_link(Proj4.TwitterClient, %{name: user1})

    #Register first user
    Proj4.TwitterClient.register_user(user1, pass1, client_pid1, pid)

    #Login first user
    assert {:ok, "Logged in successfully!!"} == Proj4.TwitterClient.login_user(user1, pass1,client_pid1, pid)

    #Unsubscribe
    assert {:error, "#{user2} doesn't exist."} == Proj4.TwitterClient.unsubscribe_from_user(user1, user2, pid)
  end

  test "The user entered to unsubscribe is not subscribed", %{server: pid} do
    user1 = "DOS15"
    user2 = "DOS16"
    pass1 = "Hello"
    pass2 = "World"

    #start clients 
    {_, client_pid1} = GenServer.start_link(Proj4.TwitterClient, %{name: user1})
    {_, client_pid2} = GenServer.start_link(Proj4.TwitterClient, %{name: user2})

    #Register first
    Proj4.TwitterClient.register_user(user1, pass1, client_pid1, pid)
    Proj4.TwitterClient.register_user(user2, pass2, client_pid2, pid)

    #Login first user
    assert {:ok, "Logged in successfully!!"} == Proj4.TwitterClient.login_user(user1, pass1, client_pid1, pid)

    #Unsubscribe
    assert {:error, "#{user1} already unsubscribed from #{user2}"} == Proj4.TwitterClient.unsubscribe_from_user(user1, user2, pid)
  end
end