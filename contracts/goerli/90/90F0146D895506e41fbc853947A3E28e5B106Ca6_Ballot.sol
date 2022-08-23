// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

contract Ballot {
  struct Voter {
    uint256 weight;
    bool voted;
    address delegate;
    uint256 vote;
  }

  struct Candidate {
    uint256 votes;
    bytes32 name;
  }

  address chairPerson; // who deployed the contract onto blockchain

  mapping(address => Voter) public voters;

  Candidate[] public candidates;
  bool public areCandidatesFreezed = false;

  constructor() {
    chairPerson = msg.sender;
    voters[chairPerson].weight = 1;
  }

  function proposalOfCandidates(bytes32[] memory proposalNames) external {
    require(
      msg.sender == chairPerson,
      "You are not authorized for this operation"
    );
    require(!areCandidatesFreezed, "candidates are freezed for this election");

    for (uint256 i = 0; i < proposalNames.length; i++) {
      candidates.push(Candidate({name: proposalNames[i], votes: 0}));
    }
    areCandidatesFreezed = true;
  }

  // a function that enables chairperson to give ability to vote to any address
  function rightToVote(address voter) external {
    require(
      msg.sender == chairPerson,
      "Only chairperson can give right to Vote"
    );

    require(!voters[voter].voted, "The voter already voted");

    require(voters[voter].weight == 0, "you are not authorized");

    voters[voter].weight = 1;
  }

  // delegate a vote to anyother voter
  function delegate(address to) external {
    Voter storage sender = voters[msg.sender];
    require(sender.weight != 0, " you are not allowed to vote");
    require(msg.sender != to, "you cannot self delegate");

    while (voters[to].delegate != address(0)) {
      to = voters[to].delegate;
      require(to != msg.sender, "found loop in delegation.");
    }

    Voter storage delegated_Voter = voters[to];

    require(voters[to].weight > 0, "delgated voter not authorized to vote");

    sender.voted = true;
    sender.delegate = to;

    if (delegated_Voter.voted) {
      candidates[delegated_Voter.vote].votes += sender.weight;
    } else {
      delegated_Voter.weight += sender.weight;
    }
  }

  function vote(uint256 candidateID) external {
    Voter storage voterInfo = voters[msg.sender];
    require(voterInfo.weight > 0, "You are not authorized to vote");
    require(!voterInfo.voted, "Your vote is already recorded");

    Candidate storage votedCandidate = candidates[candidateID];

    votedCandidate.votes += voterInfo.weight;

    voterInfo.weight = 0;
    voterInfo.voted = true;
    voterInfo.vote = candidateID;
  }

  function winningProposal() public view returns (uint256 winningProposal_) {
    uint256 winningVoteCount = 0;
    for (uint256 p = 0; p < candidates.length; p++) {
      if (candidates[p].votes > winningVoteCount) {
        winningVoteCount = candidates[p].votes;
        winningProposal_ = p;
      }
    }
  }

  function getWinnerName() external view returns (bytes32 winnerName) {
    winnerName = candidates[winningProposal()].name;
  }
}