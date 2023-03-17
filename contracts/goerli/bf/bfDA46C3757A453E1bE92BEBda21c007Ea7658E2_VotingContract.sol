// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

contract VotingContract {

    struct Candidate {
        string name;
        uint voteCount;
    }

    struct Voter {
        bool registered;
        uint vote;
    }

    mapping(address => Voter) public voters;
    mapping(uint => Candidate) public candidates;
    mapping(uint => bool) public authorizedVoters;
    mapping(uint => bool) public authorizedCandidates;
    uint public totalVotes;
    uint public numCandidates;
    uint public numVoters;
    address public owner;

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only the contract owner can perform this action");
        _;
    }

    function addCandidate(string memory _name) public onlyOwner returns (uint) {
        numCandidates++;
        candidates[numCandidates] = Candidate(_name, 0);
        return numCandidates;
    }

    function authorizeVoter(uint _voterId) public onlyOwner {
        require(_voterId > 0, "Invalid voter ID");
        authorizedVoters[_voterId] = true;
    }

    function authorizeCandidate(uint _candidateId) public onlyOwner {
        require(_candidateId > 0 && _candidateId <= numCandidates, "Invalid candidate ID");
        authorizedCandidates[_candidateId] = true;
    }

    function registerVoter(uint _voterId) public returns (uint) {
        require(!voters[msg.sender].registered, "You have already registered as a voter");
        require(_voterId > 0, "Invalid voter ID");

        // Check voter eligibility
        bool eligible = checkVotersEligibility(_voterId);
        require(eligible, "You are not eligible to register as a voter");

        numVoters++;
        voters[msg.sender] = Voter(true, 0);
        return numVoters;
    }

    function vote(uint _candidateId) public {
        Voter storage sender = voters[msg.sender];
        require(sender.registered, "You are not registered as a voter");
        require(sender.vote == 0, "You have already voted");
        require(_candidateId > 0 && _candidateId <= numCandidates, "Invalid candidate ID");

        sender.vote = _candidateId;
        candidates[_candidateId].voteCount += 1;
        totalVotes += 1;
    }

    function checkVotersEligibility(uint _voterId) public view returns (bool) {
        // Check if the voter ID is authorized
        if (!authorizedVoters[_voterId]) {
            return false;
        }

        // If all checks pass, the voter is eligible
        return true;
    }

    function checkCandidateEligibility(uint _candidateId) public view returns (bool) {
        // Check if the candidate ID is authorized
        if (!authorizedCandidates[_candidateId]) {
            return false;
        }

        // If all checks pass, the candidate is eligible
        return true;
    }
}