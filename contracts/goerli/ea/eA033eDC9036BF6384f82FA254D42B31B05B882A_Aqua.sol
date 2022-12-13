//SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

contract Aqua {
    address private votingInitiator;
    uint256 private Candidate_Id = 0;
    uint256 private Voter_Id = 0;

    //Candidate Data ---START---
    struct Candidate {
        uint256 candidateId;
        string name;
        uint256 voteCount;
        address candidateAddress;
        bool exists;
    }
    event CandidateCreate(
        uint256 indexed candidateId,
        string name,
        uint256 voteCount,
        address _address
    );

    address[] public candidateAddress;

    mapping(address => Candidate) public candidates;
    //Candidate Data ---END---

    //Voter Data ---START---
    struct Voter {
        uint256 voterId;
        string voter_name;
        address voter_address;
        uint256 voter_allowed;
        bool voter_voted;
        uint256 voter_vote1;
        uint256 voter_vote2;
    }
    event VoterCreated(
        uint256 indexed voterId,
        string voter_name,
        address voter_address,
        uint256 voter_allowed,
        bool voter_voted,
        uint256 voter_vote1,
        uint256 voter_vote2
    );
    address[] private votedVoters;
    address[] private voterAddress;
    mapping(address => Voter) public voters;

    //Voter Data ---END---
    constructor() {
        votingInitiator = msg.sender;
    }

    modifier onlyInitiator() {
        require(
            votingInitiator == msg.sender,
            "Only initiator can create the voters"
        );
        _;
    }

    //Functions
    //--Candidate--
    function setCandidate(
        address _address,
        string memory _name
    ) public onlyInitiator {
        require(
            !(candidates[_address].candidateAddress == _address),
            "The same candidate exists"
        );

        Candidate storage candidate = candidates[_address];

        candidate.candidateId = Candidate_Id;
        candidate.name = _name;
        candidate.voteCount = 0;
        candidate.candidateAddress = _address;

        candidateAddress.push(_address);

        Candidate_Id++;

        emit CandidateCreate(
            Candidate_Id,
            _name,
            candidate.voteCount,
            _address
        );
    }

    function getCandidateLength() public view returns (uint256) {
        return candidateAddress.length;
    }

    //--Voter--
    function voterRight(
        address _address,
        string memory _name
    ) public onlyInitiator {
        Voter storage voter = voters[_address];

        require(voter.voter_allowed == 0);

        voter.voter_allowed = 1;

        voter.voter_name = _name;
        voter.voter_address = _address;
        voter.voterId = Voter_Id;
        voter.voter_vote1 = 1000; //Edo tha mpei to id aytou pou pshfhse
        voter.voter_vote2 = 1000;
        voter.voter_voted = false;

        voterAddress.push(_address);

        Voter_Id++;

        emit VoterCreated(
            Voter_Id,
            _name,
            _address,
            voter.voter_allowed,
            voter.voter_voted,
            voter.voter_vote1,
            voter.voter_vote2
        );
    }

    function vote(
        address _candidate1Address,
        uint256 _candidate1VoteId,
        address _candidate2Address,
        uint256 _candidate2VoteId
    ) external {
        Voter storage voter = voters[msg.sender];

        require(!voter.voter_voted, "You have already voted");
        require(voter.voter_allowed != 0, "You have no right to vote");

        voter.voter_vote1 = _candidate1VoteId;
        candidates[_candidate1Address].voteCount += voter.voter_allowed;
        voter.voter_vote2 = _candidate2VoteId;
        candidates[_candidate2Address].voteCount += voter.voter_allowed;

        voter.voter_voted = true;
        votedVoters.push(msg.sender);
    }

    function getVoterLength() public view returns (uint256) {
        return voterAddress.length;
    }

    function getVotedVoterList() public view returns (address[] memory) {
        return votedVoters;
    }
}