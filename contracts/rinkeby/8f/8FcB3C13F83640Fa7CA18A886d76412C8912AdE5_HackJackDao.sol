// SPDX-License-Identifier: MIT
pragma solidity ^0.8.1;

contract HackJackDao{
  address payable gameAddress;
  uint256 nProposals;
  uint256 public session;

  mapping(address=>bool) voter;
  mapping(uint =>Proposal) public proposals;

  event Voted(address sender, uint transactionId);
  event Submission(uint transactionId);
  event Execution(uint transactionId);
  event Deposit(address sender, uint value);

  struct Proposal{
    address payable recipient;
    uint value;
    uint nVotes;
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

    proposals[nProposals]=Proposal(_recipient, _value,0, false);

    emit Submission(nProposals);
    nProposals+=1;

  }

  function vote(uint proposalId) public{
    require(voter[msg.sender]==true);
    require(proposalId<=nProposals);

    proposals[proposalId].nVotes+=1;
    voter[msg.sender]=false;
    emit Voted(msg.sender, proposalId);

    if(proposals[proposalId].nVotes>9){
      executeProposal(proposalId);
    }

  }
  function voteCount(uint proposalId) public view returns (uint256){
    return proposals[proposalId].nVotes;
  }







}