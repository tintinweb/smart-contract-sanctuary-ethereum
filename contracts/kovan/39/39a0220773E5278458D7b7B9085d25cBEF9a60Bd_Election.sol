//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.9;

contract Election {

    // Model a Candidate
    struct Candidate {
        uint id;
        string name;
        uint voteCount;
    }

    struct Voter {
        address voter;
        uint256 votedOn;
        Candidate candidate;
    }


    // Store accounts that have voted
    mapping(address => Voter) public voters;
    Voter[] public votersList;

    // Read/write candidates
    mapping(uint => Candidate) public candidates;

    // Store Candidates Count
    uint8 public candidatesCount;

    constructor () {
        addCandidate("Asif Ali Zardari");
        addCandidate("Imran Khan");
        addCandidate("Nawaz Shareef");
    }

    function addCandidate (string memory _name) private {
        candidatesCount ++;
        candidates[candidatesCount] = Candidate(candidatesCount, _name, 0);
    }

    function vote(uint _candidateId) public {
        // require that they haven't voted before
        require(voters[msg.sender].voter != address(0), "Already voted");

        // require a valid candidate
        require(_candidateId > 0 && _candidateId <= candidatesCount);

        // record that voter has voted
        voters[msg.sender] = Voter(msg.sender, block.timestamp, candidates[_candidateId]);
        votersList.push(voters[msg.sender]);

        // update candidate vote Count
        candidates[_candidateId].voteCount ++;
    }

}