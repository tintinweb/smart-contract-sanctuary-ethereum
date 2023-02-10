// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

contract Election {

struct Candidate {
    string name;
    uint voteCount;
}

struct Voter {
    bool authorized;
    bool voted;
    uint vote;
}

address public owner;
string public electionName;
mapping (address => Voter) public voters;
Candidate[] public candidates;
uint public totalVotes;
uint public startTime;
uint public endTime;
bool public ended;

modifier ownerOnly() {
    require(msg.sender == owner, "Only the contract owner can perform this action.");
    _;
}

constructor (string memory _name, uint _startTime, uint _endTime) {
    owner=msg.sender;
    electionName = _name;
    startTime = _startTime;
    endTime = _endTime;
    ended = false;
}

function addCandidate(string memory _name) ownerOnly public {
require(block.timestamp >= startTime && block.timestamp <= endTime, "Cannot add candidate outside of voting period.");
require(bytes(_name).length != 0, "Blank name not allowed.");
candidates.push(Candidate(_name, 0));
}

function getNumCandidate() public view returns (uint) {
    return candidates.length;
}

function authorize(address _person) ownerOnly public {
    require(block.timestamp >= startTime && block.timestamp <= endTime, "Cannot authorize outside of voting period.");
    require(_person != address(0), "Invalid address.");
    voters[_person].authorized = true;
}

function vote(uint _voteIndex) public {
    require(block.timestamp >= startTime && block.timestamp <= endTime, "Cannot vote outside of voting period.");
    require(voters[msg.sender].authorized, "Voter not authorized.");
    require(!voters[msg.sender].voted, "Voter already voted.");
    require(_voteIndex < candidates.length, "Invalid candidate index.");

    voters[msg.sender].vote = _voteIndex;
    voters[msg.sender].voted = true;
    candidates[_voteIndex].voteCount += 1;
    totalVotes += 1;
}

function deauthorize(address _person) ownerOnly public {
    require(block.timestamp >= startTime && block.timestamp <= endTime, "Cannot deauthorize outside of voting period.");
    voters[_person].authorized = false;
}

function endElection() ownerOnly public {
    require(block.timestamp >= endTime, "Cannot end election before end time.");
    ended = true;
}

function getWinner() public view returns (string memory) {
    uint maxVotes = 0;
    uint winnerIndex;
    for (uint i = 0; i < candidates.length; i++) {
        if (candidates[i].voteCount > maxVotes) {
            maxVotes = candidates[i].voteCount;
            winnerIndex = i;
        }
    }
    return candidates[winnerIndex].name;
}
}