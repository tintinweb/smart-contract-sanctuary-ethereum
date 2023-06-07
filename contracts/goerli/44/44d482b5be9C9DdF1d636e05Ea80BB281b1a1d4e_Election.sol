// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

contract Election {
    // Structure to hold candidate details
    struct Candidate {
        uint256 id;
        string name;
        uint256 voteCount;
    }

    // Array to store candidates
    Candidate[] public candidates;

    // Mapping to store if an address is authorized to vote
    mapping(address => bool) public authorizedVoters;

    // Mapping to store if an address has voted or not
    mapping(address => bool) public voters;

    // Event to notify when a vote is cast
    event VoteCast(uint256 indexed candidateId);

    // Voting start time
    uint256 public votingStartTime;

    // Voting deadline
    uint256 public votingDeadline;

    modifier votingOpen() {
        require(block.timestamp >= votingStartTime, "Voting has not started.");
        require(block.timestamp <= votingDeadline, "Voting is closed.");
        _;
    }

    // Constructor to initialize candidates and authorized voters
    constructor(
        string[] memory _names,
        address[] memory _authorizedVoters,
        uint256 _votingStartTime,
        uint256 _votingDeadline
    ) {
        // Add each candidate to the candidates array
        for (uint256 i = 0; i < _names.length; i++) {
            candidates.push(Candidate(i + 1, _names[i], 0));
        }

        // Mark each authorized voter in the authorizedVoters mapping
        for (uint256 i = 0; i < _authorizedVoters.length; i++) {
            authorizedVoters[_authorizedVoters[i]] = true;
        }

        // Set the voting deadline
        votingStartTime = _votingStartTime;
        votingDeadline = _votingDeadline;
    }

    // Function to cast a vote
    function castVote(uint256 _candidateId) public votingOpen {
        // Check if the sender is authorized to vote
        require(
            authorizedVoters[msg.sender],
            "You are not authorized to vote."
        );

        // Check if the sender has already voted
        require(!voters[msg.sender], "You have already voted.");

        // Check if the candidate exists
        require(
            _candidateId > 0 && _candidateId <= candidates.length,
            "Invalid candidate ID."
        );

        // Increment the vote count for the candidate
        candidates[_candidateId - 1].voteCount++;

        // Mark the sender as a voter
        voters[msg.sender] = true;

        emit VoteCast(_candidateId);
    }

    // Function to get the vote count for a candidate
    function getVoteCount(uint256 _candidateId) public view returns (uint256) {
        require(
            _candidateId > 0 && _candidateId <= candidates.length,
            "Invalid candidate ID."
        );
        return candidates[_candidateId - 1].voteCount;
    }

    function getStartTime() public view returns (uint256) {
        return votingStartTime;
    }

    function getDeadline() public view returns (uint256) {
        return votingDeadline;
    }

    function isAddressVoted(address _voter) public view returns (bool) {
        return voters[_voter];
    }
}