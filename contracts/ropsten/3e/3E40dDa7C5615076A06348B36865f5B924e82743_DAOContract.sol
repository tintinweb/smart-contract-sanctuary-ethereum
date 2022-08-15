// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

contract DAOContract {

  struct Proposal {
      uint256 proposalID; 
      address proposer;
      string description;
      uint256 createdAt;
      mapping(address => bool) voted;
  }

  mapping(uint256 => Proposal) public proposals;
  
  address private tokenAddress;
  uint256 private quorumPercentage;
  uint256 private votingPeriod = 45818;
  uint256 private proposeCount = 0;

  constructor(
    address _tokenAddress,
    uint256 _quorumPercentage
  ) {
    tokenAddress = _tokenAddress;
    quorumPercentage = _quorumPercentage;
  }

  function getTokenAddress() public view returns(address) {
    return tokenAddress;
  }

  function getQuorumPercentage() public view returns(uint256) {
    return quorumPercentage;
  }

  function getVotingPeriod() public view returns(uint256) {
    return votingPeriod;
  }

  function createProposal(string calldata _description) public returns(uint256) {
    uint256 proposalID = proposeCount;
    address proposer = msg.sender;

    Proposal storage newProposal = proposals[proposalID];
    newProposal.proposalID = proposeCount;
    newProposal.proposer = proposer;
    newProposal.description = _description;
    newProposal.createdAt = block.timestamp;
    newProposal.voted[msg.sender] = true;

    proposeCount = proposeCount + 1;
    return proposalID;
  }
}