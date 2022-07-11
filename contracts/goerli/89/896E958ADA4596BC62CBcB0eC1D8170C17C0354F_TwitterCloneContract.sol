/**
 *Submitted for verification at Etherscan.io on 2022-07-11
*/

//SPDX-License-Identifier: Unlicense
// contracts/TwitterContract.sol
pragma solidity ^0.8.0;

contract TwitterCloneContract {
    // Event to emit when a user tweets
    event userTwitted(
        address indexed from,
        uint256 timestamp,
        uint tweetId,
        string username,
        string tweetMessage
    );
    struct Tweet {
        address from;
        uint256 timestamp;
        uint256 tweetId;
        string username;
        string tweetMessage;
    }

    address payable owner;

    Tweet[] tweets;

    constructor() {
        owner = payable(msg.sender);
    }

    function getOwner() public view returns (address) {
        return owner;
    }

    function getTweets() public view returns (Tweet[] memory) {
        return tweets;
    }

    function postTweet(
        uint256 _tweetId,
        string memory _username,
        string memory _tweetMessage
    ) public payable {
        // Must accept more than 0 ETH for tweeting your twe
        require(msg.value > 0, "Can't tweet for free,Just pay some gas !");
        // Add the tweet to storage
        tweets.push(
            Tweet(
                msg.sender,
                block.timestamp,
                _tweetId,
                _username,
                _tweetMessage
            )
        );
        // Emit a userTwitted event with details about the the tweet.
        emit userTwitted(
            msg.sender,
            block.timestamp,
            _tweetId,
            _username,
            _tweetMessage
        );
    }
}