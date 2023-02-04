// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

contract Ownable {
    address public owner;
    
    modifier onlyOwner() {
        require(owner == msg.sender, "Not invoked by the owner");
        _;
    }
    
    constructor() {
        owner = msg.sender;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;
pragma abicoder v2;

import "./Ownable.sol";

contract USElection is Ownable {
    uint8 private constant BIDEN = 1;
    uint8 private constant TRUMP = 2;
    
    bool public electionEnded;
    
    mapping(uint8 => uint8) private seats;
    mapping(string => bool) private resultsSubmitted;
    
    struct StateResult {
        string name;
        uint votesBiden;
        uint votesTrump;
        uint8 stateSeats;
    }

    event LogStateResult(uint8 winner, uint8 stateSeats, string state);
    event LogElectionEnded(uint winner);

    modifier onlyActiveElection() {
        require(!electionEnded, "The election is not active anymore");
        _;
    }
    
    function submitStateResult(StateResult calldata result) public onlyOwner onlyActiveElection {
        require(result.stateSeats > 0, "States must have at least 1 seat");
        require(result.votesBiden != result.votesTrump, "There cannot be a tie");
        require(!resultsSubmitted[result.name], "Results are already submitted");

        resultsSubmitted[result.name] = true;

        uint8 winner;
        if(result.votesBiden > result.votesTrump) {
            winner = BIDEN;
        } else {
            winner = TRUMP;
        }
    
        seats[winner] += result.stateSeats;
        emit LogStateResult(winner, result.stateSeats, result.name);
    }
    
    function currentLeader() public view returns(uint8) {
        if(seats[BIDEN] == seats[TRUMP])
            return 0;
        return seats[BIDEN] > seats[TRUMP] ? BIDEN:TRUMP;
    }
    
    function endElection() public onlyOwner onlyActiveElection {
        electionEnded = true;
        emit LogElectionEnded(currentLeader());
    }
    
}