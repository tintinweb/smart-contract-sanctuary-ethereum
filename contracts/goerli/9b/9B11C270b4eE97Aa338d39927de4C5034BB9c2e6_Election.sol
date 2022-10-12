// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 <0.9.0;

contract Election {
    address public owner;

    event StartElection(string name, address owner);
    event Vote(address voter, string candidate);

    constructor() {
        owner = msg.sender;
    }

    struct Candidate {
        string name;
        uint256 numVotes;
    }

    struct Voter {
        string name;
        bool isAuthorized;
        uint256 votee;
        bool voted;
    }

    struct NewElection {
        string name;
        string description;
        address owner;
        Candidate[] candidates;
        mapping(address => Voter) voters;
        uint256 totalVotes;
    }

    uint256 numElections;
    mapping(uint256 => NewElection) elections;

    modifier ownerOnly() {
        require(msg.sender == owner, "You are not the contract owner!");
        _;
    }

    modifier electionOwnerOnly(uint256 _electionID) {
        require(
            msg.sender == elections[_electionID].owner,
            "You are not the election owner!"
        );
        _;
    }

    function startElection(string memory _electionName)
        public
        returns (uint256 electionID)
    {
        electionID = numElections++;
        NewElection storage e = elections[electionID];

        e.name = _electionName;
        e.owner = msg.sender;
        e.totalVotes = 0;

        emit StartElection(_electionName, msg.sender);
    }

    function addCandidate(uint256 _electionID, string memory _candidateName)
        public
        electionOwnerOnly(_electionID)
    {
        NewElection storage e = elections[_electionID];
        e.candidates.push(Candidate(_candidateName, 0));
    }

    function authorizeVoter(uint256 _electionID, address _voterAddress)
        public
        electionOwnerOnly(_electionID)
    {
        NewElection storage e = elections[_electionID];
        e.voters[_voterAddress].isAuthorized = true;
    }

    function getNumCandidates(uint256 _electionID)
        public
        view
        returns (uint256)
    {
        NewElection storage e = elections[_electionID];
        return e.candidates.length;
    }

    function vote(uint256 _electionID, uint256 _candidateID) public {
        NewElection storage e = elections[_electionID];
        require(!e.voters[msg.sender].voted, "You have already voted!");
        require(
            e.voters[msg.sender].isAuthorized,
            "You are not authorized to vote!"
        );
        e.voters[msg.sender].votee = _candidateID;
        e.voters[msg.sender].voted = true;
        e.candidates[_candidateID].numVotes++;
        e.totalVotes++;

        emit Vote(msg.sender, e.candidates[_candidateID].name);
    }

    function getTotalVotes(uint256 _electionID) public view returns (uint256) {
        NewElection storage e = elections[_electionID];
        return e.totalVotes;
    }

    function getCandidateInfo(uint256 _electionID, uint256 _candidateID)
        public
        view
        returns (Candidate memory)
    {
        NewElection storage e = elections[_electionID];
        return e.candidates[_candidateID];
    }
}