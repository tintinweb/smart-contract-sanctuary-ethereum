/**
 *Submitted for verification at Etherscan.io on 2022-09-07
*/

// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 <0.9.0;

contract Voting {
  struct Voter {
    bool voted;
    uint256 weight;
    uint256 vote;
  }

  struct Proposal {
    string name;
    uint256 voteCount;
  }

  address public chairPerson;
  uint256 public defaultVoterWeight;

  mapping(address => Voter) public voters;

  Proposal[] public proposals;

  constructor(string[] memory proposalNames, uint256 _defaultVoterWeight) {
    chairPerson = msg.sender;
    defaultVoterWeight = _defaultVoterWeight;
    voters[chairPerson].weight = defaultVoterWeight;

    for (uint256 index = 0; index < proposalNames.length; index++) {
      proposals.push(Proposal({name: proposalNames[index], voteCount: 0}));
    }
  }

  function vote(uint256 proposal) public {
    Voter storage sender = voters[msg.sender];
    require(sender.weight != 0, "Has no right to vote");
    require(!sender.voted, "Already voted");

    sender.voted = true;
    sender.vote = proposal;

    proposals[proposal].voteCount += sender.weight;
  }

  function addProposal(string memory proposalName) public {
    proposals.push(Proposal({name: proposalName, voteCount: 0}));
  }

  function removeProposal(uint256 proposalIndex) public {
    proposals[proposalIndex] = proposals[proposals.length - 1];
    proposals.pop();
  }

  function addVoter() public {
    require(!voters[msg.sender].voted, "The voter already voted.");
    require(voters[msg.sender].weight == 0);

    voters[msg.sender].weight = defaultVoterWeight;
  }

  function getAvaibleVotes() public view returns (uint256 avaibleVotes) {
    avaibleVotes = voters[msg.sender].weight;
  }

  function getWinningProposalIndex()
    public
    view
    returns (uint256 winningProposalIndex)
  {
    uint256 winningVoteCount = 0;

    for (
      uint256 proposalIndex = 0;
      proposalIndex < proposals.length;
      proposalIndex++
    ) {
      if (proposals[proposalIndex].voteCount > winningVoteCount) {
        winningVoteCount = proposals[proposalIndex].voteCount;
        winningProposalIndex = proposalIndex;
      }
    }
  }

  function getWinningProposalName()
    public
    view
    returns (string memory winningProposalName)
  {
    winningProposalName = proposals[getWinningProposalIndex()].name;
  }

  function getWinningProposalVoteCount()
    public
    view
    returns (uint256 winningVoteCount)
  {
    winningVoteCount = proposals[getWinningProposalIndex()].voteCount;
  }
}