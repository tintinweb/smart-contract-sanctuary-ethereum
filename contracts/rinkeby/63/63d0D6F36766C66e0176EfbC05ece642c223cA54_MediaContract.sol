/**
 *Submitted for verification at Etherscan.io on 2022-05-08
*/

//SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

contract MediaContract{

    struct Tweet{
        uint id;
        address username;
        string tweetText;
        bool isDeleted;
    }

    //array to add tweet
    Tweet[] private tweets;

    // mapping to track owner of tweet
    mapping(uint256 => address) tweetToOwner;

    event AddTweet(address recipient, uint tweetId);
    event DeleteTweet(uint tweetId, bool isDeleted);

    //function to add tweet
    function addTweet(string memory tweetText, bool isDeleted) external {

        uint tweetId = tweets.length;
        tweets.push(Tweet(tweetId, msg.sender, tweetText, isDeleted));
        tweetToOwner[tweetId] = msg.sender;

        emit AddTweet(msg.sender, tweetId);
    }

    function getAllTweet() external view returns(Tweet[] memory tweet){
        Tweet[] memory tempoary = new Tweet[](tweets.length);

        uint counter = 0;
        for (uint256 index = 0; index < tweets.length; index++) {
            if (tweets[index].isDeleted == false) {
                tempoary[counter] = tweets[index];
                counter++;
            } 
        }

        Tweet[] memory result = new Tweet[](counter);
        for(uint i=0; i < counter; i++){
            result[i] = tempoary[i];
        }

        return result;
    }

    //function to get only personal tweet
    function getMyTweets() external view returns(Tweet[] memory tweet){
        Tweet[] memory tempoary = new Tweet[](tweets.length);

        uint counter = 0;
        for (uint index = 0; index < tweets.length; index++) {
            if (tweetToOwner[index] == msg.sender && tweets[index].isDeleted == false) {
                tempoary[counter] = tweets[index];
                counter++;
            } 
        }

        Tweet[] memory result = new Tweet[](counter);
        for(uint i=0; i < counter; i++){
            result[i] = tempoary[i];
        }

        return result;
    }

    //function to delete tweet
    function deleteTweet(uint tweetId, bool isDeleted) external{
        if(tweetToOwner[tweetId] == msg.sender){
            tweets[tweetId].isDeleted = isDeleted;
            emit DeleteTweet(tweetId, isDeleted);
        }
    }

}