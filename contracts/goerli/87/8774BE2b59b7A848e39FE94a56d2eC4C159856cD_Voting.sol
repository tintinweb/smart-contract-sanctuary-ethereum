pragma solidity ^0.8.0;

contract Voting {
    // Define the candidates
    enum Candidate {
        Alice,
        Bob,
        Charlie
    }
    Candidate[] public candidates;

    // Define variables
    uint256 public totalVotes;
    mapping(address => bool) public voters;
    mapping(uint256 => uint256) public votes;

    // Define events
    event Vote(uint256 indexed candidateId);

    // Define the constructor
    constructor() {
        candidates.push(Candidate.Alice);
        candidates.push(Candidate.Bob);
        candidates.push(Candidate.Charlie);
        totalVotes = 0;
    }

    // Define the vote function
    function vote(uint256 candidateId) public {
        // Check if the voter has already voted
        require(!voters[msg.sender], "You have already voted");

        // Check if the candidate is valid
        require(candidateId < candidates.length, "Invalid candidate");

        // Record the vote
        votes[candidateId]++;
        totalVotes++;

        // Mark the voter as voted
        voters[msg.sender] = true;

        // Emit the Vote event
        emit Vote(candidateId);
    }

    // Define a function to get the vote count for a candidate
    function getVoteCount(uint256 candidateId) public view returns (uint256) {
        require(candidateId < candidates.length, "Invalid candidate");
        return votes[candidateId];
    }
}