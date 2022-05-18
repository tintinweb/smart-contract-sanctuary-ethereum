// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

contract Twitter {
    struct Tweet {
        string tweet;
        address creator;
        uint256 timestamp;
        mapping(address => bool) likes;
        uint256 likesCount;
    }
    struct UserInfo {
        address registeredAddress;
        string username;
        mapping(address => address) followers;
        mapping(address => address) following;
        mapping(uint256 => Tweet) tweets;
        uint256 numberOfFollowers;
        uint256 numberOfFollowing;
        uint256 numberOfTweets;
    }
    mapping(address => UserInfo) public users;

    event UserCreated(address);
    event UserDeleted(address);
    event UsernameUpdated(address, string);
    event FollowUser(address, address);
    event UnfollowUser(address, address);
    event TweetCreated(address, string, uint256);
    event TweetDeleted(address, uint256);
    event TweetLiked(address, address, uint256, uint256);
    event TweetUnliked(address, address, uint256, uint256);

    constructor() {}

    function registerUser() public {
        require(users[msg.sender].registeredAddress != msg.sender, "Address already in use");
        users[msg.sender].registeredAddress = msg.sender;
        users[msg.sender].username = "";
        users[msg.sender].numberOfFollowers = 0;
        users[msg.sender].numberOfFollowing = 0;
        users[msg.sender].numberOfTweets = 0;
        emit UserCreated(msg.sender);
    }

    function editUsername(string memory _username) public {
        users[msg.sender].username = _username;
        emit UsernameUpdated(msg.sender, _username);
    }

    function deleteUser() public {
        delete users[msg.sender];
        emit UserDeleted(msg.sender);
    }

    function getUser(address user)
        public
        view
        returns (
            address,
            string memory,
            uint256,
            uint256
        )
    {
        return (
            users[user].registeredAddress,
            users[user].username,
            users[user].numberOfFollowers,
            users[user].numberOfFollowers
        );
    }

    function getTweet(address user, uint256 id)
        public
        view
        returns (
            address,
            string memory,
            string memory,
            uint256
        )
    {
        return (
            users[user].registeredAddress,
            users[user].username,
            users[user].tweets[id].tweet,
            users[user].tweets[id].likesCount
        );
    }

    function tweet(string memory _tweet) public {
        uint256 id = users[msg.sender].numberOfTweets++;
        users[msg.sender].tweets[id].tweet = _tweet;
        users[msg.sender].tweets[id].creator = msg.sender;
        emit TweetCreated(msg.sender, _tweet, id);
    }

    function followUser(address toFollow) public {
        require(msg.sender != toFollow, "You cannot follow yoursel");
        users[toFollow].followers[msg.sender] = msg.sender;
        users[msg.sender].following[toFollow] = toFollow;
        users[msg.sender].numberOfFollowers++;
        users[msg.sender].numberOfFollowing++;
        emit FollowUser(msg.sender, toFollow);
    }

    function unfollowUser(address unfollowAddress) public {
        delete users[msg.sender].following[unfollowAddress];
        delete users[unfollowAddress].followers[msg.sender];
        users[msg.sender].numberOfFollowers--;
        users[msg.sender].numberOfFollowing--;
        emit UnfollowUser(msg.sender, unfollowAddress);
    }

    function likeTweet(address user, uint256 id) public {
        users[user].tweets[id].likes[msg.sender] = true;
        users[user].tweets[id].likesCount++;
        emit TweetLiked(msg.sender, user, id, users[user].tweets[id].likesCount);
    }

    function unlikeTweet(address user, uint256 id) public {
        delete users[user].tweets[id].likes[msg.sender];
        users[user].tweets[id].likesCount--;
        emit TweetUnliked(msg.sender, user, id, users[user].tweets[id].likesCount);
    }
}