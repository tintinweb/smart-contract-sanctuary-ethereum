// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 <0.9.0;

contract Election {
    bool public paused = false;
    address public owner;

    constructor() {
        owner = msg.sender;
    }

    struct Candidate {
        string name;
        uint256 numVotes;
    }

    struct Voter {
        bool isAuthorized;
        uint256 votee;
        bool voted;
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
        uint256 totalVotes;
        bool opened;
        bool closed;
    }

    uint256 public numElections;

    // Struct containing a (nested) mapping cannot be constructed in memory.
    // NewElection[] elections;
    mapping(uint256 => NewElection) public elections; // _electionID starts from 0

    modifier ownerOnly() {
        require(msg.sender == owner, "You are not the contract owner!");
        _;
    }

    modifier pausedOnly() {
        require(paused, "The contract is currently not paused!");
        _;
    }

    modifier notPausedOnly() {
        require(!paused, "The contract is currently paused!");
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
            elections[_electionID].opened,
            "The election is not yet opened!"
        );
        _;
    }

    modifier electionNotOpenedOnly(uint256 _electionID) {
        require(
            !elections[_electionID].opened,
            "The election is already opened!"
        );
        _;
    }

    modifier electionNotClosedOnly(uint256 _electionID) {
        require(
            !elections[_electionID].closed,
            "The election is already closed!"
        );
        _;
    }

    event CreateElection(uint256 _electionID, string name, address owner);
    event OpenElection(uint256 _electionID, string name, address owner);
    event CloseElection(uint256 _electionID, string name, address owner);
    event Vote(address voter, string candidate);

    function pause(bool _state) public ownerOnly {
        paused = _state;
    }

    function createElection(string memory _electionName)
        public
        notPausedOnly
        returns (uint256 _electionID)
    {
        _electionID = numElections++;
        NewElection storage e = elections[_electionID];

        e.name = _electionName;
        e.owner = msg.sender;
        e.totalVotes = 0;
        e.opened = false;
        e.closed = false;

        emit CreateElection(_electionID, _electionName, msg.sender);
    }

    function deleteElection(uint256 _electionID) public ownerOnly pausedOnly {
        for (uint256 i = _electionID; i < numElections - 1; i++) {
            // Types in storage containing (nested) mappings cannot be assigned to.
            //elections[i] = elections[i + 1];
            NewElection storage e1 = elections[i + 1];
            NewElection storage e = elections[i];
            e = e1;
        }
        delete elections[numElections];
        numElections--;
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
        e.candidates.push(Candidate(_candidateName, 0));
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
        e.candidates.pop();
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
        e.voters[_voterAddress].isAuthorized = true;
        e.voterInfos.push(VoterInfo(_voterAddress, _voterName));
    }

    function unauthorizeVoter(uint256 _electionID, address _voterAddress)
        public
        notPausedOnly
        electionOwnerOnly(_electionID)
        electionNotClosedOnly(_electionID)
    {
        NewElection storage e = elections[_electionID];
        require(!e.voters[_voterAddress].voted, "The voter has already voted!");
        e.voters[_voterAddress].isAuthorized = false;

        bool found = false;
        for (uint256 i = 0; i < e.voterInfos.length - 1; i++) {
            if (e.voterInfos[i].addr == _voterAddress) found = true;
            if (found) e.voterInfos[i] = e.voterInfos[i + 1];
        }
        e.candidates.pop();
    }

    function openElection(uint256 _electionID)
        public
        notPausedOnly
        electionOwnerOnly(_electionID)
        electionNotOpenedOnly(_electionID)
        electionNotClosedOnly(_electionID)
    {
        NewElection storage e = elections[_electionID];
        e.opened = true;

        emit OpenElection(_electionID, e.name, e.owner);
    }

    function closeElection(uint256 _electionID)
        public
        notPausedOnly
        electionOwnerOnly(_electionID)
        electionOpenedOnly(_electionID)
        electionNotClosedOnly(_electionID)
    {
        NewElection storage e = elections[_electionID];
        e.closed = true;

        emit CloseElection(_electionID, e.name, e.owner);
    }

    function vote(uint256 _electionID, uint256 _candidateIndex)
        public
        notPausedOnly
        electionOpenedOnly(_electionID)
        electionNotClosedOnly(_electionID)
    {
        NewElection storage e = elections[_electionID];
        require(!e.voters[msg.sender].voted, "You have already voted!");
        require(
            e.voters[msg.sender].isAuthorized,
            "You are not authorized to vote!"
        );
        e.voters[msg.sender].votee = _candidateIndex;
        e.voters[msg.sender].voted = true;
        e.candidates[_candidateIndex].numVotes++;
        e.totalVotes++;

        emit Vote(msg.sender, e.candidates[_candidateIndex].name);
    }

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

    function getNumCandidates(uint256 _electionID)
        public
        view
        returns (uint256)
    {
        NewElection storage e = elections[_electionID];
        return e.candidates.length;
    }

    function getNumVoters(uint256 _electionID) public view returns (uint256) {
        NewElection storage e = elections[_electionID];
        return e.voterInfos.length;
    }

    function getTotalVotes(uint256 _electionID) public view returns (uint256) {
        NewElection storage e = elections[_electionID];
        return e.totalVotes;
    }
}