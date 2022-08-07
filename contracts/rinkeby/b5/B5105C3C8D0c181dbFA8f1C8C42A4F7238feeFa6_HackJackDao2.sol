// SPDX-License-Identifier: MIT
pragma solidity ^0.8.1;

contract HackJackDao2{
  address payable gameAddress;
  uint256 nProposals;
  uint256 public session;

  mapping(address=>bool) public voter;
  mapping(uint =>Proposal) public proposals;

  event Voted(address sender, uint transactionId);
  event Submission(uint transactionId);
  event Execution(uint transactionId);
  event Deposit(address sender, uint value);

  struct Proposal{
    address payable recipient;
    uint value;
    uint nVotes;
    uint sessionId;
    bool executed;
  }

  constructor(address payable _gameAddress){
    gameAddress=_gameAddress;
  }

  receive() payable external{
    emit Deposit(msg.sender, msg.value);
  }

  function becomeVoter() public{

    voter[msg.sender]=true;

  }

  function executeProposal(uint proposalId) private{
    (bool success, )=proposals[proposalId].recipient.call{value: proposals[proposalId].value}("");
    require(success, "Failed to execute proposal");
    proposals[proposalId].executed=true;
    session+=1;
    emit Execution(proposalId);
  }

  function submitProposal(address payable _recipient, uint _value) public{
    require(voter[msg.sender]==true);

    proposals[nProposals]=Proposal(_recipient, _value,0,session, false);

    emit Submission(nProposals);
    nProposals+=1;

  }

  function vote(uint proposalId) public{
    require(voter[msg.sender]==true, "You are not a voter");
    require(proposalId<=nProposals,"Incorrect ProposalId");
    require(proposals[proposalId].sessionId==session,"This Proposal has expired");

    proposals[proposalId].nVotes+=1;
    voter[msg.sender]=false;
    emit Voted(msg.sender, proposalId);

    if(proposals[proposalId].nVotes>1){
      executeProposal(proposalId);
    }

  }
  function voteCount(uint proposalId) public view returns (uint256){
    return proposals[proposalId].nVotes;
  }







}