// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Election {

    struct Candidate {
        uint id;
        string name;
        uint voteCount;
    }

    uint public candidateCount;

    mapping(uint => Candidate) public candidates;

    mapping(address => bool) public voters;

    event votedEvent (uint indexed candidateId);

    constructor() {
        addCandidate("Candidate 1");
        addCandidate("Candidate 2");
    }

    function addCandidate(string memory _name) private {
        candidateCount++;
        candidates[candidateCount] = Candidate(candidateCount, _name, 0);
    }

    function clearVoter(address voter) public {
        voters[voter] = false;
    }

    function vote(uint _candidateId) public {
        // ensure voter hasn't already voted before
        require(!voters[msg.sender]);

        // ensure candidate id is valid
        require(_candidateId > 0 && _candidateId <= candidateCount);

        voters[msg.sender] = true;

        candidates[_candidateId].voteCount++;

        emit votedEvent(_candidateId);
    }

}