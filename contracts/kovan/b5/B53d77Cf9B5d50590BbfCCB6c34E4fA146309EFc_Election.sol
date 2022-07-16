// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.5.0 < 0.9.0;

contract Election {

    struct Candidate {
        string name;
        uint numVotes;
    }

    struct Voter {
        string name;
        bool canVote;
        bool voted;
        bool registered;
        uint candidateIndex;
    }

    address public chairman;
    uint public totalVotes;
    uint public totalVoters;
    Candidate[] public candidates;
    string public electionName;
    mapping(address => Voter) public voters;
    bool public electionStarted = false;

    modifier onlyOwner() {
        require(msg.sender == chairman, "Only the chairman can alter something.");
        _;
    }

    event CanditateAdded(Candidate candidate);
    event VoteCasted(Candidate[] candidates, uint totalVotes);
    event ElectionStarted();
    event VoterRegistered(uint totalVoters);

    constructor() {
        chairman = msg.sender;
        totalVotes = 0;
    }

    function initializeElection(string memory _electionName) public onlyOwner {
        electionName = _electionName;
    }

    function startElection() public onlyOwner {
        electionStarted = true;
        emit ElectionStarted();
    }

    function addCandidate(string memory _name) onlyOwner public  {
        require(electionStarted == false, "Election started already");
        Candidate memory candidate = Candidate(_name, 0);
        candidates.push(candidate);
        emit CanditateAdded(candidate);
    }

    function authorizeVoter(address _address) public onlyOwner {
        require(electionStarted == false, "Election have started already");
        voters[_address].canVote = true;
    }

    function getCandidateCount() public view returns(uint) {
        return candidates.length;
    }

    function vote(uint candidateIndex) public {
        require(electionStarted == true, "Elected have not started");
        require(voters[msg.sender].voted == false, "You already voted");
        require(voters[msg.sender].canVote == true, "You cannot vote");
        voters[msg.sender].voted = true;
        voters[msg.sender].candidateIndex = candidateIndex;

        candidates[candidateIndex].numVotes += 1;
        totalVotes+=1;
        emit VoteCasted(candidates, totalVotes);
    }

    function registerAsVoter(string memory _name) public {
        require(voters[msg.sender].registered == false, "You are registered already, wait till the election starts");
        voters[msg.sender] = Voter(_name, false, false, true, 0);
        totalVoters+=1;
        emit VoterRegistered(totalVoters);
    }
    
    function getCandidates() public view returns(Candidate[] memory){
        return candidates;
    }

}