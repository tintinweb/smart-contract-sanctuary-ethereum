// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;

contract VotingSmartContract  {
    // Candidate struct to store candidate information
    struct Candidate {
        uint id;
        string name;
        uint voteCount;
    }

    // Voter struct to store voter information
    struct Voter {
        bool authorized;
        bool voted;
    }

    // Election struct to store election information
    struct Election {
        uint id;
        string title;
        uint startTimestamp;
        uint endTimestamp;
    }

    // Mapping to store election data with election ID as the key
    mapping(uint => Election) public elections;
    // Separate mapping for each election's candidates
    mapping(uint => mapping(uint => Candidate)) public electionCandidates;
    // Separate mapping for each election's candidate counts
    mapping(uint => uint) public electionCandidatesCount;
    // Mapping to store voter data with voter's Ethereum address as the key
    mapping(address => Voter) public voters;
    // Mapping to store administrator data with administrator's Ethereum address as the key
    mapping(address => bool) public administrators;

    uint public electionsCount; // Counter for the total number of elections
    address public owner; // Address of the contract owner

    // Event emitted when a vote is cast
    event votedEvent(uint indexed _electionId, uint indexed _candidateId);

    // Constructor to set the contract owner as the deployer of the contract
    constructor() {
        owner = msg.sender;
    }

    // Modifier to restrict access to the contract owner
    modifier onlyOwner {
        require(msg.sender == owner, "Only the owner can perform this action");
        _;
    }

    // Modifier to restrict access to administrators
    modifier onlyAdmin {
        require(administrators[msg.sender], "Only administrators can perform this action");
        _;
    }

    // Function to add an administrator, callable only by the contract owner
    function addAdministrator(address _admin) public onlyOwner {
        administrators[_admin] = true;
    }

    // Function to create a new election, callable only by administrators
    function createElection(string memory _title, uint _startTimestamp, uint _endTimestamp) public onlyAdmin returns (uint) {
        electionsCount++;
        elections[electionsCount] = Election(electionsCount, _title, _startTimestamp, _endTimestamp);
        return electionsCount;
    }

    // Function to add a candidate to an election, callable only by administrators
    function addCandidate(uint _electionId, string memory _name) public onlyAdmin {
        require(_electionId > 0 && _electionId <= electionsCount, "Invalid election");
        electionCandidatesCount[_electionId]++;
        electionCandidates[_electionId][electionCandidatesCount[_electionId]] = Candidate(electionCandidatesCount[_electionId], _name, 0);
    }

    // Function to authorize a voter, callable only by administrators
    function authorize(address _voter) public onlyAdmin {
        voters[_voter].authorized = true;
    }

    // Function to cast a vote for a candidate in an election
    function vote(uint _electionId, uint _candidateId) public {
        require(voters[msg.sender].authorized, "Voter is not authorized");
        require(!voters[msg.sender].voted, "Voter has already voted");
        require(_electionId > 0 && _electionId <= electionsCount, "Invalid election");
        
        Election storage election = elections[_electionId];
        require(block.timestamp >= election.startTimestamp && block.timestamp <= election.endTimestamp, "Election not in progress");
        require(_candidateId > 0 && _candidateId <= electionCandidatesCount[_electionId], "Invalid candidate");

        voters[msg.sender].voted = true;
        electionCandidates[_electionId][_candidateId].voteCount++;

        emit votedEvent(_electionId, _candidateId);
    }

    // Function to get the election results, callable only by administrators
    function getResult(uint _electionId) public view onlyAdmin returns (uint[] memory _voteCounts) {
        require(_electionId > 0 && _electionId <= electionsCount, "Invalid election");
        uint candidatesCount = electionCandidatesCount[_electionId];
        _voteCounts = new uint[](candidatesCount);
        for (uint i = 1; i <= candidatesCount; i++) {
            _voteCounts[i - 1] = electionCandidates[_electionId][i].voteCount;
        }
    }
}