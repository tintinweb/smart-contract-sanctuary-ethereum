// SPDX-License-Identifier: MIT
pragma solidity ^0.8.1;
contract VoteContract {
address public owner;
uint candidateCount;
uint voterCount;
bool start;
bool end;
// Constructor
function voteContract() public {
   owner = msg.sender;
   candidateCount = 0;
   voterCount = 0;
   start = false;
   end = false;
}
function getOwner() public view returns(address) {
   return owner;
}
// Only Admin can access
modifier onlyAdmin() {
   require(msg.sender == owner);
   _;
}
struct Candidate{
   string name;
   string stakeholder;
   uint voteCount;
   uint voteID;
   uint candidateId;
}
mapping(uint => Candidate) public candidateDetails;
// Only admin can add candidate
function addCandidate(string memory _name, string memory _stakeholder, uint _voteID) public onlyAdmin {
   Candidate memory newCandidate = Candidate({
     name : _name,
     stakeholder : _stakeholder,
     voteCount : 0,
     voteID : _voteID,
     candidateId : candidateCount
   });
   candidateDetails[candidateCount] = newCandidate;
   candidateCount += 1;
}
// get total number of candidates
function getCandidateNumber() public view returns (uint) {
   return candidateCount;
}
struct Voter{
   address voterAddress;
   string name;
   uint constituency;
   bool hasVoted;
   bool isVerified;
}
address[] public voters;
mapping(address => Voter) public voterDetails;
// request to be added as voter
function requestVoter(string memory _name, uint _constituency) public {
   Voter memory newVoter = Voter({
     voterAddress : msg.sender,
     name : _name,
     constituency : _constituency,
     hasVoted : false,
     isVerified : false
   });
   voterDetails[msg.sender] = newVoter;
   voters.push(msg.sender);
   voterCount += 1;
}
// get total number of voters
function getVoterCount() public view returns (uint) {
   return voterCount;
}
function verifyVoter(address _address) public onlyAdmin {
   voterDetails[_address].isVerified = true;
}
function vote(uint candidateId) public{
   require(voterDetails[msg.sender].hasVoted == false);
   require(voterDetails[msg.sender].isVerified == true);
   require(start == true);
   require(end == false);
   candidateDetails[candidateId].voteCount += 1;
   voterDetails[msg.sender].hasVoted = true;
}
// ENable Voting
function startElection() public onlyAdmin {
   start = true;
   end = false;
}
// Disable Voting
function endElection() public onlyAdmin {
   end = true;
   start = false;
}
function getStart() public view returns (bool) {
   return start;
}
function getEnd() public view returns (bool) {
   return end;
}
}