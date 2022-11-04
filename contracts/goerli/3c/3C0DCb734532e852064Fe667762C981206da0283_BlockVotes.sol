//SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

contract BlockVotes {
    //Struct to store each Candidate's Data
    struct Candidate {
        uint id;
        string name;
        uint voteCount;
    }
    //Struct to store Voter's Data
    struct voter {
        string voterName;
        bool voted;
    }

    //**************VARIABLE DECLARATION***************//
    uint public candidatesCount;
    uint public timestamp;
    uint public voteDuration;
    uint public totalVoters;
    // address public owner;
    // bool public voteStart;
    bool public votingLive;
    // store accounts which have voted
    mapping(address => bool) public voters;
    // Store, Fetch & Map Candidate data into candidates
    // Store Candidate Count
    mapping(uint => Candidate) public candidates;
    mapping(address => voter) public voterRegister;

    //************  EVENTS  ************//
    event votedEvent(uint indexed _candidateId);
    event voterAdded(address voter);
    event voteStarted();

    //only the contract owner should be able to start voting
    address public owner;
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    constructor() {
        owner = msg.sender;
        timestamp = block.timestamp;
        votingLive = false;
    }

    //**************WRITABLE FUNCTIONS***************//

    //function to start vote: onlyOwner can trigger
    function startVote(uint voteMinutes) public onlyOwner {
        voteDuration = voteMinutes * 1 minutes;
        votingLive = true;

        //if(block.timestamp < voteDuration) {votingLive = false;}
        emit voteStarted();
    }

    //function to end votes: onlyOfficer
    function endVote() public onlyOwner {
        votingLive = false;
    }

    //function to enable officials add new candidates
    function addCandidate(string memory _name) public onlyOwner {
        candidatesCount++;
        candidates[candidatesCount] = Candidate(candidatesCount, _name, 0);
    }

    //add voter
    function addVoter(address _voterAddress, string memory _voterName)
        public
        onlyOwner
    {
        voter memory v;
        v.voterName = _voterName;
        v.voted = false;
        voterRegister[_voterAddress] = v;
        totalVoters++;
        emit voterAdded(_voterAddress);
    }

    //function to enable voters cast vote
    function vote(uint _candidateId) public {
        // require Voter's info is in register
        require(bytes(voterRegister[msg.sender].voterName).length != 0);
        // require that address hasn't voted before
        require(!voters[msg.sender], "Already voted!");
        //require voting is live
        require(votingLive == true, "Vote isn't Live");
        // require vote only for valid candidate
        require(
            _candidateId > 0 && _candidateId <= candidatesCount,
            "Not Found"
        );

        // require time duration for vote has not ended
        require(timestamp >= voteDuration, "Time is up");

        // record that voter has voted
        voters[msg.sender] = true;

        // update candidate vote count
        candidates[_candidateId].voteCount++;

        // trigger vote event
        emit votedEvent(_candidateId);
    }

    //function to get total numbers of vote each candidates have
    function checkCandidateVote(uint _candidateId) public view returns (uint) {
        return candidates[_candidateId].voteCount;
    }

    //Lets user know if their vote has been counted
    function haveYouVoted() public view returns (bool) {
        return voters[msg.sender];
    }

    //function to enable change of ownership
    function changeOwnership(address _newOwner) public onlyOwner {
        owner = _newOwner;
    }
}