/**
 *Submitted for verification at Etherscan.io on 2022-07-18
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

contract VotingContract {

  address[] public Voters;
  mapping (address => uint) public votes;

  address[] public Candidates;
  uint public numberOfCandidates;
  uint public numberOfVoters;

  constructor(address[] memory FirstCandidates) public {
    for (uint i = 0; i < FirstCandidates.length; i++) {
      Candidates.push(FirstCandidates[i]);
      numberOfCandidates++;
    }
    //PriceToAdd = priceToAdd;
    //PriceToVote = priceToVote;
  }

  function addCandidate(address Candidate) public payable {
    require(!CandidateExists(Candidate));
    //require(msg.value == PriceToAdd);
    Candidates.push(Candidate);
    numberOfCandidates++;
  }

  function voteForCandidate(address Candidate) public payable {
    // require(msg.value == PriceToVote);
    require(CandidateExists(Candidate));
    require(!HasVoted(msg.sender));
    votes[Candidate] += 1;
    Voters.push(msg.sender);
    numberOfVoters++;
  }

  function CandidateExists(address Candidate) view public returns (bool) {
    for(uint i = 0; i < numberOfCandidates; i++) {
      if (Candidates[i] == Candidate) {
        return true;
      }
    }
    return false;
  }

  function HasVoted(address Voter) view public returns (bool) {
    for(uint i = 0; i < Voters.length; i++) {
      if (Voters[i] == Voter) {
        return true;
      }
    }
    return false;
  }

  function VotesForCandidate(address Candidate) view public returns (uint) {
    return votes[Candidate];
  }

}