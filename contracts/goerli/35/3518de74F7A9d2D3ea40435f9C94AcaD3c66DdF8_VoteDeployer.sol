//SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;
pragma abicoder v2;

contract Vote {    
    uint8 public choices;
    uint public endTimestamp; 

    event Results(uint24[] results);

    // Mapping of voter address to voted choice
    // Voting choices ids start from 1
    mapping(address => uint8) public voterChoices;

    //Mapping of choice id to number of votes for it
    mapping(uint8 => uint24) public votes;

    modifier voteEnded {
        require(block.timestamp > endTimestamp, "Voting has not ended");
        _;
    }
        
    modifier voteNotEnded{
        require(block.timestamp < endTimestamp, "Voting has ended");
        _;
    }

    modifier validateChoiceId(uint8 id) {
        require(id > 0 && id <= choices, "Invalid choice");
        _;
    }

    constructor(uint8 _choices, uint daysAfter){
        choices = _choices;
        endTimestamp = block.timestamp + daysAfter * 1 days;
    }

    function vote(uint8 _choiceId) public voteNotEnded validateChoiceId(_choiceId) {
        require(voterChoices[msg.sender] == 0, "You have already voted");
        voterChoices[msg.sender] = _choiceId;
        votes[_choiceId] += 1;
    }

    function readVoteById(uint8 id) public view voteEnded validateChoiceId(id) returns(uint24) {
        return votes[id];
    }

    function readAllVote() public voteEnded {
        uint24[] memory results = new uint24[](choices);
        for(uint8 i = 0; i < choices; i++){
            results[i] = readVoteById(i+1); 
        }
        emit Results(results);
    }

    receive() external payable {
        revert("Error: receive function cannot be called.");
    }
      
    fallback() external payable {
        revert("Error: fallback function cannot be called.");
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;
pragma abicoder v2;

import "./Vote.sol";

contract VoteDeployer {    
    mapping(address => address[]) public contractsAddressList; 

    Vote public vote; 
    event DeployedContract(address contractAddress);

    function deployVote(uint8 _choices, uint daysAfter) public returns(address){
        vote = new Vote(_choices, daysAfter);
        contractsAddressList[msg.sender].push(address(vote));
        return address(vote);
    }

    receive() external payable {
        revert("Error: receive function cannot be called.");
    }
      
    fallback() external payable {
        revert("Error: fallback function cannot be called.");
    }
}