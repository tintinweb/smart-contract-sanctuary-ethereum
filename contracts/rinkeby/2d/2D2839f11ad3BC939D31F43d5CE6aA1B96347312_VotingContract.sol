/**
 *Submitted for verification at Etherscan.io on 2022-07-20
*/

pragma solidity ^0.4.18;

contract VotingContract {

  //uint public PriceToAdd;
  //uint public PriceToVote;

  address[] Voters;
  mapping (address => uint) public votes;

  address[] public Candidates;
  uint public numberOfCandidates;

  function VotingContract(address[] FirstCandidates) public {
    for (uint i = 0; i < FirstCandidates.length; i++) {
      Candidates.push(FirstCandidates[i]);
      numberOfCandidates++;
    }
    //PriceToAdd = priceToAdd;
    //PriceToVote = priceToVote;
  }

  function addCandidate(address Candidate) public payable {
    require(!CandidateExists(Candidate));
    // require(msg.value == PriceToAdd);
    Candidates.push(Candidate);
    numberOfCandidates++;
  }


  function voteForCandidate(address Candidate) public payable {
    // require(msg.value == PriceToVote);
    require(CandidateExists(Candidate));
    require(!HasVoted(msg.sender));
    votes[Candidate] += 1;
    Voters.push(msg.sender);
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