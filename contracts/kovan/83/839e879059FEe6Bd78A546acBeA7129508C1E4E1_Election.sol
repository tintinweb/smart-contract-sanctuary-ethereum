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
    }


    // Store accounts that have voted
    mapping(address => Voter) public voters;
    Voter[] private votersList;

    // Read/write candidates
    mapping(uint256 => Candidate) public candidates;

    // Store Candidates Count
    uint256 public candidatesCount;

    constructor () {
        addCandidate("Asif Ali Zardari");
        addCandidate("Imran Khan");
        addCandidate("Nawaz Shareef");
    }

    function addCandidate (string memory _name) private {
        candidatesCount ++;
        candidates[candidatesCount] = Candidate(candidatesCount, _name, 0);
    }

    function vote(uint256 _candidateId) public {
        // require that they haven't voted before
        require(voters[msg.sender].voter != address(0), "Already voted");

        // require a valid candidate
        require(_candidateId > 0 && _candidateId <= candidatesCount, "not a valid customer ID");

        // record that voter has voted
        Voter memory _voter = Voter(msg.sender, block.timestamp);
        voters[msg.sender] = _voter; 
        votersList.push(_voter);

        // update candidate vote Count
        candidates[_candidateId].voteCount++;
    }

    function getVotersList() public view returns (Voter[] memory){
        return votersList;
    }

}