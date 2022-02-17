// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;
pragma abicoder v2;

import "./Ownable.sol";

contract USElection is Ownable{
    uint8 public constant BIDEN = 1;
    uint8 public constant TRUMP = 2;

    bool public electionEnded;

    mapping(uint => uint) public seats;
    mapping(string => bool) public resultsSubmitted;

    struct StateResult {
        string name;
        uint votesBiden;
        uint votesTrump;
        uint stateSeats;
    }

    event LogStateResult(uint8 winner, uint stateSeats, string state);
    event LogElectionEnded(uint winner);

    modifier onlyActiveElection() {
        require(!electionEnded, "Election has ended already");
        _;
    }

    function submitStateResult(StateResult calldata result) public onlyActiveElection onlyOwner {
        require(result.stateSeats > 0, "States must have at least one seat");
        require(result.votesBiden != result.votesTrump, "There cannot be a tie");
        require(!resultsSubmitted[result.name], "The result for this state has already been submitted!");
        uint8 winner;
        if(result.votesTrump > result.votesBiden) {
            winner = TRUMP;
        } else {
            winner = BIDEN;
        }
        
        seats[winner] += result.stateSeats;
        resultsSubmitted[result.name] = true;

        emit LogStateResult(winner, result.stateSeats, result.name);
    }

    function currentLeader() public view returns(uint8){
        if(seats[BIDEN] > seats[TRUMP]) {
            return BIDEN;
        }
        if(seats[TRUMP] > seats[BIDEN]) {
            return TRUMP;
        }
        return 0;
    }

    function endElection() public onlyOwner {
        electionEnded = true;
        emit LogElectionEnded(currentLeader());
    }

}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

contract Ownable {
    address public owner;

    modifier onlyOwner() {
        require(msg.sender == owner, "Ownable: caller is not the owner");
        _;
    }

    constructor() {
        owner = msg.sender;
    }
}