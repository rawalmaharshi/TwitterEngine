# PROJECT 4.1: TWITTER ENGINE 


## Group Members

Maharshi Rawal

Mohit Garg


### Instructions to run the project 

To run the project:  

```
mix run proj4.exs numUsers numTweets

e.g: mix run proj4.exs 100 15 
```

To run the test cases:  

``` mix test ```
 

### What is Working 

The following functionalities are working: 

- Register account and delete account 

- Send Tweets (including hashtags and mentions) 

- Subscribe to user’s tweets 

- Re-tweet (User would get an option to re-tweet, to be implemented in front-end) 

- Allow querying tweets subscribed to, tweets with hashtags and mentions 

- Live tweets delivery 
 

### Implementation details: 

We have implemented the following functionalities. In twitter engine a user can send the tweets, register his account, delete his account, login, logout and many other functionalities. We used ETS data storage for storing the data provided by the user. All the functionalities are explained below: 

 

- Register account: A user must register an account to use the twitter engine. To register an account, a username and password are required. If a user tries to send tweets without registering an account, an error is thrown. 

- Login: A user can login into the portal using the username and password. 

- Delete Account: User can delete their account after passing the authentication of username and password. If the authentication is correct, then the user is deleted from the system. 

- Send Tweets: A user can send tweet while being online. User can use hashtags to tweet about common happenings around. When a hashtag is used in a tweet, an entry gets created in the hashtag table. When subsequent tweet about the same hashtag is found, that tweet is added to the hashtag. When a user is mentioned in a tweet. An entry gets updated in the user’s tweets. 

- Subscribe to user: A user can subscribe to the tweets of another user. There is also a functionality of unsubscribing from the subscribed user. 

- Re-tweets: In case of an interesting tweet encountered by a user, he/she gets an option to retweet it. 

- Subscribe to hashtag: User can subscribe to any hashtag and get the post related to that hashtag whenever someone post a tweet. They may also unsubscribe.  
 

## Testcases Implemented: 

1. Tests to check the Registration of the user 

   i) User registers successfully 

   ii) A duplicate user is not registered into the system 

2. Tests for Login 

   i) Login fails when the user is not registered 

   ii) Login fails when a wrong password is entered 

   iii) Successful user login 

   iv) Error shown when the user is already logged in 

3. Tests for Logout 

   i) Logout fails when there is no user for that username 

   ii) Logout fails when the user is not logged in 

   iii) Successful logout of user 

4. Tests for Deleting User Account 

   i) If the user exists, then it is deleted 

   ii) If the user doesn’t exist, an error occurs 

5. Tests for Subscribing Another User 

   i) Correctly subscribe to another user 

   ii) Fail to subscribe, when the other user is not present 

6. Test for Unsubscribing Another User 

   i) Correctly unsubscribe from another user 

   ii) Fail to unsubscribe when the other user is not registered/ wrong username 

   iii) Fail to unsubscribe when the user is not yet subscribed 

7. Test to Send Tweet  

   i) Fail to send tweet because the user is not logged in. 

   ii) Fail to send tweet when user is not registered. 

   iii) Successfully send tweet 

8. Test for Hashtags and mentions 

   i) Entry into hashtag table when a tweet consists of a hashtag 

   ii) In user mentions, an entry is done in mentioned user's table 

   iii) Retweet functionality, returns a list of tweets (prompts user to retweet in frontend) 