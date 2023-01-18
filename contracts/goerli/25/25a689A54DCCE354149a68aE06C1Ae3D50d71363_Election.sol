// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 <0.9.0;

contract Election {
    //---------
    // Structs
    //---------
    struct Candidate {
        string name;
        uint256 numOfVotes;
    }

    struct Voter {
        bool isAuthorized;
        uint256 votee;
        bool hasVoted;
    }

    struct VoterInfo {
        address addr;
        string name;
    }

    struct NewElection {
        string name;
        string description;
        address owner;
        Candidate[] candidates; // _candidateIndex starts from 0
        mapping(address => Voter) voters;
        VoterInfo[] voterInfos;
        uint256 numOfVotes;
        bool isOpened;
        bool isClosed;
    }

    //------------------------
    // Public state variables
    //------------------------
    bool public isPaused = false;
    address public owner;

    uint256 public totalNumOfElections;
    uint256 public totalNumOfCandidates;
    uint256 public totalNumOfVoters;
    uint256 public totalNumOfVotes;

    // Struct containing a (nested) mapping cannot be constructed in memory.
    // NewElection[] elections;
    mapping(uint256 => NewElection) public elections; // _electionID starts from 0

    //-------------
    // Constructor
    //-------------
    constructor() {
        owner = msg.sender;
    }

    //-----------
    // Modifiers
    //-----------
    modifier ownerOnly() {
        require(msg.sender == owner, "You are not the contract owner!");
        _;
    }

    modifier pausedOnly() {
        require(isPaused, "The contract is currently not paused!");
        _;
    }

    modifier notPausedOnly() {
        require(!isPaused, "The contract is currently paused!");
        _;
    }

    modifier electionOwnerOnly(uint256 _electionID) {
        require(
            msg.sender == owner || msg.sender == elections[_electionID].owner,
            "You are neither the contract owner nor the election owner!"
        );
        _;
    }

    modifier electionOpenedOnly(uint256 _electionID) {
        require(
            elections[_electionID].isOpened,
            "The election is not yet opened!"
        );
        _;
    }

    modifier electionNotOpenedOnly(uint256 _electionID) {
        require(
            !elections[_electionID].isOpened,
            "The election is already opened!"
        );
        _;
    }

    modifier electionNotClosedOnly(uint256 _electionID) {
        require(
            !elections[_electionID].isClosed,
            "The election is already closed!"
        );
        _;
    }

    //--------
    // Events
    //--------
    event Vote(address indexed voter, string candidate);
    event ElectionUpdate(
        uint256 indexed id,
        string name,
        address indexed owner,
        string summary,
        uint256 numOfCandidates,
        uint256 numOfVoters,
        uint256 numOfVotes,
        uint256 totalNumOfElections,
        uint256 totalNumOfCandidates,
        uint256 totalNumOfVoters,
        uint256 totalNumOfVotes
    );

    //--------------------------------
    // Functions - Wrtie transactions
    //--------------------------------
    function pause(bool _state) public ownerOnly {
        isPaused = _state;
        string memory _summary = isPaused
            ? "Elections paused"
            : "Elections resumed";

        // Emit event(s)
        emit ElectionUpdate(
            0,
            "",
            msg.sender,
            _summary,
            0,
            0,
            0,
            totalNumOfElections,
            totalNumOfCandidates,
            totalNumOfVoters,
            totalNumOfVotes
        );
    }

    function createElection(string memory _electionName)
        public
        notPausedOnly
        returns (uint256 _electionID)
    {
        // Set the elction ID and update the total number of the elections
        _electionID = totalNumOfElections++;
        // Create an election
        NewElection storage e = elections[_electionID];
        e.name = _electionName;
        e.owner = msg.sender;
        e.numOfVotes = 0;
        e.isOpened = false;
        e.isClosed = false;

        // Emit event(s)
        emit ElectionUpdate(
            _electionID,
            _electionName,
            msg.sender,
            "Election created",
            0, // e.candidates.length
            0, // e.voterInfos.length
            0, // e.numOfVotes
            totalNumOfElections,
            totalNumOfCandidates,
            totalNumOfVoters,
            totalNumOfVotes
        );
    }

    function deleteElection(uint256 _electionID) public ownerOnly pausedOnly {
        // Prepare for the event arguments
        NewElection storage e = elections[_electionID];
        string memory _electionName = e.name;
        address _electionOwner = e.owner;
        uint256 _numOfCandidates = e.candidates.length;
        uint256 _numOfVoters = e.voterInfos.length;
        uint256 _numOfVotes = e.numOfVotes;

        for (uint256 i = _electionID; i < totalNumOfElections - 1; i++) {
            // Types in storage containing (nested) mappings cannot be assigned to.
            //elections[i] = elections[i + 1];
            NewElection storage e1 = elections[i + 1];
            NewElection storage e0 = elections[i];
            e0 = e1;
        }
        // Delete an election
        delete elections[totalNumOfElections];
        // Update the total numbers
        totalNumOfElections--;
        totalNumOfCandidates -= _numOfCandidates;
        totalNumOfVoters -= _numOfVoters;
        totalNumOfVotes -= _numOfVotes;

        // Emit event(s)
        emit ElectionUpdate(
            _electionID,
            _electionName,
            _electionOwner,
            "Election deleted",
            _numOfCandidates,
            _numOfVoters,
            _numOfVotes,
            totalNumOfElections,
            totalNumOfCandidates,
            totalNumOfVoters,
            totalNumOfVotes
        );
    }

    function editElectionName(uint256 _electionID, string memory _electionName)
        public
        notPausedOnly
        electionOwnerOnly(_electionID)
        electionNotOpenedOnly(_electionID)
        electionNotClosedOnly(_electionID)
    {
        NewElection storage e = elections[_electionID];
        e.name = _electionName;
    }

    function editElectionDescription(
        uint256 _electionID,
        string memory _electionDescription
    )
        public
        notPausedOnly
        electionOwnerOnly(_electionID)
        electionNotOpenedOnly(_electionID)
        electionNotClosedOnly(_electionID)
    {
        NewElection storage e = elections[_electionID];
        e.description = _electionDescription;
    }

    function addCandidate(uint256 _electionID, string memory _candidateName)
        public
        notPausedOnly
        electionOwnerOnly(_electionID)
        electionNotOpenedOnly(_electionID)
        electionNotClosedOnly(_electionID)
    {
        NewElection storage e = elections[_electionID];
        // Add a candidate
        e.candidates.push(Candidate(_candidateName, 0));
        // Update the total number of the candidates
        totalNumOfCandidates++;

        // Emit event(s)
        emit ElectionUpdate(
            _electionID,
            e.name,
            e.owner,
            "Candidate added",
            e.candidates.length,
            e.voterInfos.length,
            0, // e.numOfVotes
            totalNumOfElections,
            totalNumOfCandidates,
            totalNumOfVoters,
            totalNumOfVotes
        );
    }

    function removeCandidate(uint256 _electionID, uint256 _candidateIndex)
        public
        notPausedOnly
        electionOwnerOnly(_electionID)
        electionNotOpenedOnly(_electionID)
        electionNotClosedOnly(_electionID)
    {
        NewElection storage e = elections[_electionID];
        for (uint256 i = _candidateIndex; i < e.candidates.length - 1; i++) {
            e.candidates[i] = e.candidates[i + 1];
        }
        // Remove a candidate
        e.candidates.pop();
        // Update the total number of the candidates
        totalNumOfCandidates--;

        // Emit event(s)
        emit ElectionUpdate(
            _electionID,
            e.name,
            e.owner,
            "Candidate removed",
            e.candidates.length,
            e.voterInfos.length,
            0, // e.numOfVotes
            totalNumOfElections,
            totalNumOfCandidates,
            totalNumOfVoters,
            totalNumOfVotes
        );
    }

    function authorizeVoter(
        uint256 _electionID,
        address _voterAddress,
        string memory _voterName
    )
        public
        notPausedOnly
        electionOwnerOnly(_electionID)
        electionNotClosedOnly(_electionID)
    {
        NewElection storage e = elections[_electionID];
        // Authorize a voter
        e.voters[_voterAddress].isAuthorized = true;
        // Add a voter info
        e.voterInfos.push(VoterInfo(_voterAddress, _voterName));
        // Update the total number of the voters
        totalNumOfVoters++;

        // Emit event(s)
        emit ElectionUpdate(
            _electionID,
            e.name,
            e.owner,
            "Voter authorized",
            e.candidates.length,
            e.voterInfos.length,
            e.numOfVotes,
            totalNumOfElections,
            totalNumOfCandidates,
            totalNumOfVoters,
            totalNumOfVotes
        );
    }

    function unauthorizeVoter(uint256 _electionID, address _voterAddress)
        public
        notPausedOnly
        electionOwnerOnly(_electionID)
        electionNotClosedOnly(_electionID)
    {
        NewElection storage e = elections[_electionID];
        require(
            !e.voters[_voterAddress].hasVoted,
            "The voter has already voted!"
        );
        // Unauthorize a voter
        e.voters[_voterAddress].isAuthorized = false;

        bool isFound = false;
        for (uint256 i = 0; i < e.voterInfos.length - 1; i++) {
            if (e.voterInfos[i].addr == _voterAddress) isFound = true;
            if (isFound) e.voterInfos[i] = e.voterInfos[i + 1];
        }
        // Remove a voter info
        e.voterInfos.pop();
        // Update the total number of the voters
        totalNumOfVoters--;

        // Emit event(s)
        emit ElectionUpdate(
            _electionID,
            e.name,
            e.owner,
            "Voter unauthorized",
            e.candidates.length,
            e.voterInfos.length,
            e.numOfVotes,
            totalNumOfElections,
            totalNumOfCandidates,
            totalNumOfVoters,
            totalNumOfVotes
        );
    }

    function openElection(uint256 _electionID)
        public
        notPausedOnly
        electionOwnerOnly(_electionID)
        electionNotOpenedOnly(_electionID)
        electionNotClosedOnly(_electionID)
    {
        NewElection storage e = elections[_electionID];
        e.isOpened = true;

        // Emit event(s)
        emit ElectionUpdate(
            _electionID,
            e.name,
            e.owner,
            "Election opened",
            e.candidates.length,
            e.voterInfos.length,
            0, // e.numOfVotes
            totalNumOfElections,
            totalNumOfCandidates,
            totalNumOfVoters,
            totalNumOfVotes
        );
    }

    function closeElection(uint256 _electionID)
        public
        notPausedOnly
        electionOwnerOnly(_electionID)
        electionOpenedOnly(_electionID)
        electionNotClosedOnly(_electionID)
    {
        NewElection storage e = elections[_electionID];
        e.isOpened = false;
        e.isClosed = true;

        // Emit event(s)
        emit ElectionUpdate(
            _electionID,
            e.name,
            e.owner,
            "Election closed",
            e.candidates.length,
            e.voterInfos.length,
            e.numOfVotes,
            totalNumOfElections,
            totalNumOfCandidates,
            totalNumOfVoters,
            totalNumOfVotes
        );
    }

    function vote(uint256 _electionID, uint256 _candidateIndex)
        public
        notPausedOnly
        electionOpenedOnly(_electionID)
        electionNotClosedOnly(_electionID)
    {
        NewElection storage e = elections[_electionID];
        require(!e.voters[msg.sender].hasVoted, "You have already voted!");
        require(
            e.voters[msg.sender].isAuthorized,
            "You are not authorized to vote!"
        );
        // Update the voter record
        e.voters[msg.sender].votee = _candidateIndex;
        e.voters[msg.sender].hasVoted = true;
        // Increment vote
        e.candidates[_candidateIndex].numOfVotes++;
        e.numOfVotes++;
        // Update the total number of the votes
        totalNumOfVotes++;

        // Emit event(s)
        emit Vote(msg.sender, e.candidates[_candidateIndex].name);
        emit ElectionUpdate(
            _electionID,
            e.name,
            e.owner,
            "New vote",
            e.candidates.length,
            e.voterInfos.length,
            e.numOfVotes,
            totalNumOfElections,
            totalNumOfCandidates,
            totalNumOfVoters,
            totalNumOfVotes
        );
    }

    //-------------------------------
    // Functions - Read transactions
    //-------------------------------
    function getCandidateInfo(uint256 _electionID, uint256 _candidateIndex)
        public
        view
        returns (Candidate memory)
    {
        NewElection storage e = elections[_electionID];
        return e.candidates[_candidateIndex];
    }

    function getVoterInfo(uint256 _electionID, uint256 _voterIndex)
        public
        view
        returns (VoterInfo memory)
    {
        NewElection storage e = elections[_electionID];
        return e.voterInfos[_voterIndex];
    }

    function getNumOfCandidates(uint256 _electionID)
        public
        view
        returns (uint256)
    {
        NewElection storage e = elections[_electionID];
        return e.candidates.length;
    }

    function getNumOfVoters(uint256 _electionID) public view returns (uint256) {
        NewElection storage e = elections[_electionID];
        return e.voterInfos.length;
    }

    function getNumOfVotes(uint256 _electionID) public view returns (uint256) {
        NewElection storage e = elections[_electionID];
        return e.numOfVotes;
    }
}