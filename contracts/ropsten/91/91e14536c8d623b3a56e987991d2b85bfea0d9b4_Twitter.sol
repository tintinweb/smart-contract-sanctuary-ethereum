/**
 *Submitted for verification at Etherscan.io on 2022-08-23
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

contract Twitter {

    address public owner;
    address public contractAddress;

    struct Tweet {
        string _id;
        address _creator;
        bool _closed;
        uint256 _createdAt;
    }

    struct Message {
        address _creator;
        string _content;
        uint256 _createdAt;
    }

    mapping(string => Tweet) public tweets;
    mapping(string => Message[]) public messages;
    mapping(string => uint) public count;
    mapping(address => bool) public blacklist;

    constructor() {
        owner = msg.sender;
        contractAddress = address(this);
    }

    function createTweet(string memory _id, string memory _message) public BlackList {
        tweets[_id] = Tweet(_id, msg.sender, false, block.timestamp);
        replyTweet(_id, _message);
    }

    function replyTweet(string memory _id, string memory _message) public TweetExists(_id) TweetClosed(_id) {
        messages[_id].push(Message(msg.sender, _message, block.timestamp));
    }

    function tweetClosed(string memory _id) public view returns(bool) {
        return bool(tweets[_id]._closed);
    }

    function tweetReplyCount(string memory _id) public view returns(uint) {
        return uint(messages[_id].length);
    }

    function closeTweet(string memory _id) public TweetOwner(_id) TweetClosed(_id) TweetExists(_id) {
        tweets[_id]._closed = true;
    }

    modifier TweetClosed(string memory _id) {
        require(tweets[_id]._closed == bool(false), "Tweet is closed");
        _;
    }

    modifier TweetExists(string memory _id) {
        require(tweets[_id]._creator != address(0), "Tweet does not exist");
        _;
    }

    modifier TweetOwner(string memory _id) {
        require(tweets[_id]._creator == msg.sender, "You do not own this tweet");
        _;
    } 

    modifier BlackList() {
        require(!blacklist[msg.sender], "Not allowed to create tweet");
        _;
    }

}