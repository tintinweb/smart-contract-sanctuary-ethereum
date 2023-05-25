//SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;
pragma abicoder v2;

contract Vote {    
    uint8 public choices;
    uint public endTimestamp; 

    // Mapping of voter address to voted choice
    // Voting choices ids start from 1
    mapping(address => uint8) public voterChoices;

    //Mapping of choice id to number of votes for it
    mapping(uint8 => uint24) private votes;

    modifier voteEnded {
        require(block.timestamp > endTimestamp, "Voting has not ended");
        _;
    }
        
    modifier voteNotEnded{
        require(block.timestamp < endTimestamp, "Voting has ended");
        _;
    }

    modifier validateChoiceId(uint8 _id) {
        require(_id > 0 && _id <= choices, "Invalid choice");
        _;
    }

    constructor(uint8 _choices, uint8 _daysAfter){
        choices = _choices;
        endTimestamp = block.timestamp + _daysAfter * 1 days;
    }

    function vote(uint8 _choiceId) public voteNotEnded validateChoiceId(_choiceId) {
        require(voterChoices[msg.sender] == 0, "You have already voted");
        voterChoices[msg.sender] = _choiceId;
        votes[_choiceId] += 1;
    }

    function readVoteById(uint8 _id) public view voteEnded validateChoiceId(_id) returns(uint24) {
        return votes[_id];
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
    event DeployedContract(address _contractAddress);

    function deployVote(uint8 _choices, uint8 _daysAfter) public {
        vote = new Vote(_choices, _daysAfter);
        contractsAddressList[msg.sender].push(address(vote));
        emit DeployedContract(address(vote));
    }

    receive() external payable {
        revert("Error: receive function cannot be called.");
    }
      
    fallback() external payable {
        revert("Error: fallback function cannot be called.");
    }
}