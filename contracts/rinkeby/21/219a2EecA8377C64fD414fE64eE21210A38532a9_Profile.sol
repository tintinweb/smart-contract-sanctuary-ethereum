/**
 *Submitted for verification at Etherscan.io on 2022-05-27
*/

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

contract Profile {
    address public owner;
    address[] public tweets;

    constructor () {
        owner = msg.sender;
    }

    function getTweetsLength() public view returns (uint) {
        return tweets.length;
    }

    function createTweet(string memory _text) public {
        require(msg.sender == owner, "It's not you profile!");
        Tweet tweet = new Tweet(owner, _text);
        tweets.push(address(tweet));
    }
}

contract Tweet {
    address public owner;
    string public text;
    uint32 public time;

    constructor (address _owner, string memory _text) {
        text = _text;
        time = uint32(block.timestamp);
        owner = _owner;
    }
}