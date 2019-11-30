num_users = String.to_integer(Enum.at(System.argv(),0), 10)
num_tweets = String.to_integer(Enum.at(System.argv(),1), 10)
run_type = Enum.at(System.argv(), 2)
Proj4.main([num_users, num_tweets, run_type])