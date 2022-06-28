/**
 *Submitted for verification at Etherscan.io on 2022-06-27
*/

/**
 *Submitted for verification at Etherscan.io on 2022-06-26
*/

pragma solidity ^0.8.15;
//SPDX-License-Identifier: UNLICENSED

contract VotingFactory {

    //-- Mapping of the poll's ID to its number of options, to validate vote requests
    mapping (uint256 => uint256) internal pollOptions;

    //-- Timestamp of the most recent address poll creation, by address.
    //-- Utilized when limiting upload rates. 
    mapping (address => uint256) internal lastPollUploadTime; 

    constructor () { }

    struct Poll{
      address owner;
      string  title;
      bytes32[]  options;
    }

    struct PollSummary{   
      Poll[] polls;
    }

    /**
      * @notice 
      * This is an array where are kept all the polls that are made in the Contract.
      */
      Poll[] public polls;

    event PollCreated(address indexed owner, string title);

    /**
      * @notice 
      * This function adds a poll to the polls array.
      * It has an additional security for poll create rate limiting because every address has the ability to create polls. 
      * Once in every minute.
      *
      * @param title    - Title of the poll
      * @param options  - All the options of this poll
      *
      */
      function addPoll(string memory title, bytes32[] memory options) public {
        require(lastPollUploadTime[msg.sender] + 60 <= block.timestamp, 'Can upload once per minute');
        
        //-- Structuring the poll
        polls.push();
        uint256 index = polls.length - 1;
        polls[index].owner = msg.sender;
        polls[index].title = title;
        for (uint256 i = 0; i < options.length; i += 1){
          polls[index].options.push(options[i]);
        }

        //-- Keeps track of how many choices a poll has for simpler calculations
        pollOptions[index] = options.length;
        //-- saving time during poll creation for rate control
        lastPollUploadTime[msg.sender] = block.timestamp;

        emit PollCreated(msg.sender, title);
    }

    /**
      * @notice 
      * This function return every poll.
      * With every possible option.
      * Getter function for struct is decleared because solidity cant get nested arrays from struct.
      *
      * @return summary - Struct of polls summary
      */
      function getPolls() public view returns(PollSummary memory){
        PollSummary memory summary = PollSummary(polls);
        return summary; 
    }  

    /**
      * @notice 
      * This function returns poll by ID.
      * With every possible option.
      * Getter function for struct is decleared because solidity cant get nested arrays from struct.
      *
      * @param id - ID of the poll
      *
      * @return summary - Struct of polls summary
      */
      function getPoll(uint256 id) public view returns(Poll memory){
        Poll memory p = polls[id];
        return p;
    }

    /**
      * @notice 
      * This function counts every poll.
      * Returns every one with every possible option.
      *
      * @param id - ID of the poll
      *
      * @return pollOptions - Quantity of requested poll options.
      */
      function pollOptionsCount(uint256 id) public view returns (uint256){
        return pollOptions[id];
    }

}


contract VotingPoll is VotingFactory{

    //-- Voter addresses contain nested mappings of the poll options they selected.
    mapping(address => mapping(uint256 => uint256)) public votedOptionFor;

    //-- Mapping to see if an address has already cast a vote.
    mapping(address => mapping(uint256 => bool)) public voted;

    event Vote(address indexed user, uint256 pollId, uint256 optionId);

    constructor () { }

    /**
      * @notice 
      * This function casts a vote for the poll.
      * One vote per address.
      *
      * @param pollId   - ID of the poll
      * @param optionId - ID of the poll's option
      */
      function vote(uint256 pollId, uint256 optionId) public {
        uint256 optionsCount = pollOptionsCount(pollId);
        require (voted[msg.sender][pollId] == false, "Already voted for this poll");
        require (optionId < optionsCount && optionId >= 0, "Wrong Option ID");
        
        votedOptionFor[msg.sender][pollId] = optionId;
        voted[msg.sender][pollId] = true;
        
        emit Vote(msg.sender, pollId, optionId);
    }
   
}