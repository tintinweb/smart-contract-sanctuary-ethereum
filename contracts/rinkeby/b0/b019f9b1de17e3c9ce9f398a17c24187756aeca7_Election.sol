/**
 *Submitted for verification at Etherscan.io on 2022-07-30
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Election {

    struct Candidate {
        uint id;
        string name;
        uint voteCount;
        string details;
        string election_id;
    }

    mapping(uint => Candidate) public candidates;
    mapping(address => bool) public voters;

    uint public candidatesCount;

    string public candidate;

    constructor() public {}

    event votedEvent(
        uint indexed _candidateId
    );

    function addCandidate(string memory _name, string memory _details, string memory _election_id) public {
        candidatesCount++;
        candidates[candidatesCount] = Candidate(candidatesCount, _name, 0, _details, _election_id);
    }

    function vote(uint _candidateId) public {
        require(!voters[msg.sender]);

        require(_candidateId > 0 && _candidateId <= candidatesCount);
        
        voters[msg.sender] = true;
        
        candidates[_candidateId].voteCount++;
    
        emit votedEvent(_candidateId);
    }

}