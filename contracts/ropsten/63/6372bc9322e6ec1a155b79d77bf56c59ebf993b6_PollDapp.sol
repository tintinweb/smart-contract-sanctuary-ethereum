/**
 *Submitted for verification at Etherscan.io on 2022-04-09
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

contract PollDapp {
// Allow an ethereum address to cast a vote only once: msg. sender

    string public question;
    string[] public options;
    mapping (uint => uint) public voteCount;
    mapping (address => uint) public castedVotes;
    constructor (string memory _question, string[] memory _options) {
        question = _question;    
        options =_options;
    }

    function getOptions() public view returns (string[] memory) {
        return options;
    }

    function castVote (uint _optionIndex) public returns (string memory) {
        address _caller = msg. sender;
        
        uint existingNumberOfVotes = voteCount[_optionIndex];
        uint updatedNumberOfVotes = existingNumberOfVotes + 1;

        uint existingVotesByCaller = castedVotes[_caller];

        require(existingVotesByCaller == 0, "Error: You can only cast once");

        uint updatedVotesByCaller = existingVotesByCaller +1;

        voteCount[_optionIndex] = updatedNumberOfVotes;
        castedVotes[_caller] = updatedVotesByCaller;

        return "Congrats, Your Vote is counted";


    }
}