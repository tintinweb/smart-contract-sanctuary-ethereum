// SPDX-License-Identifier: MIT
pragma solidity 0.8.0;

// @project EPITA 2022
// @title Creating a contract called `EthereumTwitter`
contract EthereumTwitter {
  /* @notice Tweets Struct includes
  // @param id, tweet, author, timestamp, likes, address who likes a tweet, array storing comments */
  struct Tweets {
    uint id;
    string tweet;
    address author;
    uint timestamp;
    uint likes;
    mapping (address => bool) likedBy;
    Comment[] comments;
  }
  /* @notice Comment Struct includes
  // @param id, comment, author, timestamp */
  struct Comment {
    uint id;
    string comment;
    address author;
    uint timestamp;
  }

  /* @notice Creating an array of Tweets (struct) object, that store tweets inside
  // @dev Initialize nextTweetId to be 0 by default (@ start)
  // @dev Map the addresses of users who tweets into integers */
  Tweets[] public tweets;
  uint public nextTweetId = 0;
  mapping(address => uint[]) userTweets;

  /* @notice Event that will be invoked
  // @dev When a new NewTweet is created (return the sender address, the id, the tweet, and the time of the tweet)
  // @dev When a new Comment is created (return the sender, the id, the comment, and the time of the comment) */
  event NewTweet(address author, uint id, string tweet, uint timestamp);
  event NewComment(address author, uint id, string comment, uint timestamp);

  // @notice No need to add anything in the constructure
  constructor() payable {}

  /* Modifiers are a convenient way to validate input from
  // functions. `hasLiked` is applied to `unlikeTweet` below:
  // The new function body is the modifier body where
  // `_` is replaced by the old function body. */
  modifier hasLiked(uint _id) {
    Tweets storage tweet = tweets[_id];
    require(tweet.likedBy[msg.sender] == true);
    _;
  }


  /* Modifier `hasNotLiked` is applied to `likeTweet` below:
  // The new function body is the modifier body where
  // `_` is replaced by the old function body. */
  modifier hasNotLiked(uint _id) {
    Tweets storage tweet = tweets[_id];
    require(tweet.likedBy[msg.sender] == false);
    _;
  }

  /* A function `createTweet` that takes a strings as tweet and stores it in the memoery.
  // This function is payable due to the fact that it will be written on the blockchain so a transaction fee is needed.
  // With the help of the struct, the function will store: the `id` of the tweet, the `tweet`, the `author` (address) of the tweeter,
  // the `timestamp` (time) of the tweet, and the `likes` that the tweet got. 
  // Add a incremental tweeterId
  //@notice `emit` to create an new event. */
  function createTweet(string memory _tweet) public payable {
    Tweets storage tweet = tweets.push();
    tweet.id = nextTweetId;
    tweet.tweet = _tweet;
    tweet.author = msg.sender;
    tweet.timestamp = block.timestamp;
    tweet.likes = 0;
    userTweets[msg.sender].push(nextTweetId);
    nextTweetId++;
    emit NewTweet(msg.sender, nextTweetId, _tweet, block.timestamp);
  }

  /* A function `likeTweet` that takes the id of a particular tweet.
  // We use the modifier `hasNotLiked` to make sure that this tweet is not already liked by this user.
  // we then increment the tweet likes by 1 */
  function likeTweet(uint _id) external hasNotLiked(_id)  {
    Tweets storage tweet = tweets[_id];
    tweet.likedBy[msg.sender] = true;
    tweet.likes++;
  }

  /* A function `unlikeTweet` that takes the id of a particular tweet.
  // We use the modifier `hasLiked` to make sure that this tweet is already liked by this user.
  // we then decrement the tweet likes by 1 */
  function unlikeTweet(uint _id) external hasLiked(_id) {
    Tweets storage tweet = tweets[_id];
    tweet.likedBy[msg.sender] = false;
    tweet.likes--;
  }

  /* A function `addComment` that takes a strings as comment to stores it in the memoery, and the id of the tweet to comment.
  // This function is payable due to the fact that it will be written on the blockchain so a transaction fee is needed.
  // With the help of the struct, the function will store: the `id` of the comment, the `comment`, the `author` (address) of the comment,
  // and the `timestamp` (time) of the comment.
  //@notice `emit` to create an new event. */
  function addComment(string memory _comment, uint _id) public payable {
    Tweets storage tweet = tweets[_id];
    uint commentId = tweet.comments.length;
    Comment storage comment = tweet.comments.push();
    comment.comment = _comment;
    comment.author = msg.sender;
    comment.timestamp = block.timestamp;
    comment.id = commentId;
    emit NewComment(msg.sender, commentId, _comment, block.timestamp);
  }

  /* A function `getUserTweets` that takes the address of a particular user
  // and return an array of the tweetID's of the user. */
  function getUserTweets(address _user) public view returns (uint[] memory) {
    return userTweets[_user];
  }

  /* A function `getTweetComments` that takes a TweetID
  // and return a tuple (an array) of the comments on that tweet. */
  function getTweetComments(uint _id) public view returns (Comment[] memory) {
    return tweets[_id].comments;
  }

  /* A function `getTweetLength`
  // that returns the number of tweets using the length. */
  function getTweetLength() public view returns (uint) {
    return tweets.length;
  }

  /* A function `getLikedByTweet` that takes a TweetID
  // and returns true if the tweet has a like. */
  function getLikedByTweet(uint _id) public view returns (bool) {
    return tweets[_id].likedBy[msg.sender];
  }

}