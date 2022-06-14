/**
 *Submitted for verification at Etherscan.io on 2022-06-14
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

contract PollDapp{
    string public question;
    string[] public options;

    mapping (uint => uint) public voteCount; //option index->number of votes for that option
    mapping (address => uint) public castedVotes;

    constructor (string memory _question, string[] memory _options){
        question = _question;
        options = _options;
    }

    function getOptions() public view returns (string[] memory){
        return options;
    }

    function castVote(uint _optionIndex) public returns (string memory){
        require(castedVotes[msg.sender] == 0, "Error: You can only vote once!");
        address _caller = msg.sender;

        uint existingVotes = voteCount[_optionIndex];
        uint updatedVotes = existingVotes + 1;

        uint existingVotesCasted = castedVotes[_caller];

        

        uint updatedVotesCasted = existingVotesCasted + 1;

        voteCount[_optionIndex] = updatedVotes;
        castedVotes[_caller] = updatedVotesCasted;

        return "Your vote has been polled successfully!";
    } 
}