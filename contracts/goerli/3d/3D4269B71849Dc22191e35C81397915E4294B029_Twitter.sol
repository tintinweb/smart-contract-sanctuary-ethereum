/**
 *Submitted for verification at Etherscan.io on 2022-11-01
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;


contract Twitter {

    struct Tweet{
        uint256 id;
        uint256 tweetTime;
        address senderAddress;
        string tweet;
        bool isActive;
    }

    uint256 totalTweetsCounter;
    uint256 deletedTweetsCounter;

    mapping(uint256 => Tweet) public tweets;
    //Tweet[] public tweets;

    event NewTweet(uint256 index);
    event DeleteTweet(uint256 index, bool status);
    event EditTweet(uint256 index, string newTweet);

    /// @notice The tweet does not belong to you
    error UnauthorizedAccess();
    /// @notice The tweet is already deleted
    error DeletedTweet();
    /// @notice Provided id does not exist
    error IdError();
    /// @notice Tweet exceeds allowed max length
    error InvalidMessage();

    constructor() {
        totalTweetsCounter = 0;
        deletedTweetsCounter = 0;
    }
    
    function remove(uint index)  external {

        Tweet storage tweetToDelete = tweets[index];

        if (tweetToDelete.senderAddress == address(0)){
            revert IdError();
        }

        if (msg.sender != tweetToDelete.senderAddress){
            revert UnauthorizedAccess();
        }

        if (!tweetToDelete.isActive){
            revert DeletedTweet();
        }

        tweetToDelete.isActive = false;

        deletedTweetsCounter++;
        
        emit DeleteTweet(index, false);
    }

    //need to understand better the difference between memory and calldata keywords for input pameter and how it effects 
    //performance and gas cost
    function addTweet(string memory message) external {

        if (bytes(message).length > 280) revert InvalidMessage();

        tweets[totalTweetsCounter] = Tweet({
            id: totalTweetsCounter,
            tweetTime: block.timestamp,
            senderAddress: msg.sender,
            tweet: message,
            isActive: true
        });
        
        totalTweetsCounter++;

        emit NewTweet(totalTweetsCounter);
    }

    function editTweet(uint index, string calldata newMessage) external {

        if (bytes(newMessage).length > 280) revert InvalidMessage();

        if(tweets[index].senderAddress == address(0)){
            revert IdError();
        }

        Tweet storage tweetToEdit = tweets[index];

        //Ensures only tweet owners can edit tweets
        if (msg.sender != tweetToEdit.senderAddress){
            revert UnauthorizedAccess();
        }

        //Ensures onluy active tweets can be deleted
        if (!tweetToEdit.isActive){
            revert DeletedTweet();
        }

        tweetToEdit.tweet = newMessage;

        emit EditTweet(index, newMessage);
    }

    function getTweets() external view returns (Tweet [] memory){

        Tweet[] memory allActiveTweets = new Tweet[](totalTweetsCounter-deletedTweetsCounter);
        uint256 indexTracker = 0;

         for (uint256 i = 0; i < totalTweetsCounter; i++) {
            if (tweets[i].isActive){
                allActiveTweets[indexTracker] = tweets[i];
                indexTracker++;
            }
        }

        return allActiveTweets;
    }

    function getValidTweetsLength() external view returns (uint256){
        return totalTweetsCounter - deletedTweetsCounter;
    }

}