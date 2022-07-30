/**
 *Submitted for verification at Etherscan.io on 2022-07-29
*/

// SPDX-License-Identifier: MIT
pragma solidity >0.8.0 <0.9.0;

contract Election {

    address internal owner;
    uint public candidateCount;

    struct Candidate {
        uint id;
        string name;
        uint votes;
    }

    mapping(uint => Candidate) public candidates;
    mapping(address => bool) public votedOrNot;

    event Voted (
        uint id,
        string name,
        uint voteCount
    );

    event electionUpdate (
        uint indexed candidateId
    );

    modifier onlyOwner{
        require(msg.sender==owner,"not the owner");
        _;
    }
    

    constructor(){
        msg.sender==owner;
    }


    function addCandiate (string memory name) public onlyOwner {
        candidateCount ++;
        candidates[candidateCount] = Candidate(candidateCount, name, 0);
    }

    function vote(uint _candidateId) public {
        require(!votedOrNot[msg.sender], "You already voted for the candiate");
        // require a valid candidate.
        require(_candidateId > 0 && _candidateId < candidateCount);

        candidates[_candidateId].votes ++;
        votedOrNot[msg.sender] = false;

        emit Voted(_candidateId, candidates[_candidateId].name, candidates[_candidateId].votes);
    }
}