// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

contract Election {
    
    struct Candidate {
        uint id;
        string name;
        uint voteCount;
        string party;
    }

    mapping(uint => Candidate) public candidates;
    mapping(address => bool) public voters;

    uint public candidatesCount;
    uint public voteTotal;

    event addCandidateEvent (uint indexed_candidateId);
    event votedEvent (uint indexed_candidateId);

    function addCandidate(string memory _name, string memory _party) public {
        require(voteTotal == 0, "Cannot submit candidate after first vote recorded");

        candidatesCount++;
        candidates[candidatesCount] = Candidate(candidatesCount, _name, 0, _party);

        emit addCandidateEvent(candidatesCount);
    }

    function getCandidateTotal() view public returns(uint) {
        return candidatesCount;
    }

    function getCandidate(uint _candidateId) view public returns(Candidate memory){
        return candidates[_candidateId];
    }

    // vote takes candidate id, 
    function vote(uint _candidateId) public {
        // require that they haven't voted before
        require(!voters[msg.sender], "Vote already cast from this address");

        // require a valid candidate, making sure their index is in mapping
        require(_candidateId > 0 && _candidateId <= candidatesCount, "Candidate ID is not in range of candidates");

        require(candidatesCount >= 2, "Must be at least 2 candidates before votes can be cast");

        // record that voter has voted, making their address key true
        voters[msg.sender] = true;

        // update candidate vote Count, for matched id, based on key
        candidates[_candidateId].voteCount++;
        voteTotal++;

        // trigger voted event
        emit votedEvent(_candidateId);
    }
}