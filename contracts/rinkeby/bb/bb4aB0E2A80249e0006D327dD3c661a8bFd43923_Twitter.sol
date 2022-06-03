/**
 *Submitted for verification at Etherscan.io on 2022-06-03
*/

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

contract Twitter {
    mapping(address => address) public usersToProfiles;
    mapping(address => bool) public isAddressTweet;
    mapping(address => bool) public isAddressProfile;

    function createProfile() public {
        require(usersToProfiles[msg.sender] == address(0), "You already have a profile!");
        Profile profile = new Profile(this, msg.sender);
        usersToProfiles[msg.sender] = address(profile);
        isAddressProfile[address(profile)] = true;
    }

    function setAddressTweet(address _tweetAddress) public {
        require(isAddressProfile[msg.sender], "hahhahah, no!");
        isAddressTweet[_tweetAddress] = true;
    }

}

contract Profile {
    Twitter public twitter;
    address public owner;
    address[] public tweets;

    modifier onlyOwner{
        require(msg.sender == owner, "It's not you profile!");
        _;
    }

    constructor (Twitter _twitter, address _owner) {
        twitter = _twitter;
        owner = _owner;
    }

    function getTweetsLength() public view returns (uint) {
        return tweets.length;
    }

    function createTweet(string memory _text) public onlyOwner{
        Tweet tweet = new Tweet(owner, _text);
        tweets.push(address(tweet));
        twitter.setAddressTweet(address(tweet));
    }

    function retweet(address tweetAddress) public onlyOwner{
        require(twitter.isAddressTweet(tweetAddress), "It's not a tweet!");
        tweets.push(tweetAddress);
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