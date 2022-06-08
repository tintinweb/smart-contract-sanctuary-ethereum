/**
 *Submitted for verification at Etherscan.io on 2022-06-08
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.4;

contract Election {

  struct Voter {
      bool voted;
      bool isEligible;
      uint optionSelected;
  }  

  struct Option {
      string name;
      uint votes;
  }

  address admin;

  uint public totalVoters;

  mapping(address => Voter) voters;

  Option[] options;

  uint startTime = 0;
  uint endTime;

  constructor(string[] memory optionNames) {
      admin = msg.sender;

      voters[admin].isEligible = true;

      for (uint i = 0; i < optionNames.length; i++) {
          options.push(
              Option({
                  name : optionNames[i],
                  votes : 0
              })
          );
      }
  }

  function giveTheRightToVote(address to) public {
      require(msg.sender == admin, "Only chairperson can give the right to vote");
      require(!voters[to].isEligible, "Already has the right to vote!");
      require(to != admin, "Chairperson can not give the right to their self");

      voters[to].isEligible = true;

      totalVoters += 1;
  } 

  function startPolling() public {
      require(msg.sender == admin, "Only chairperson has the right to start polling!");

      startTime = block.number;
      endTime = startTime + 7200;
  }

  function vote(uint option) external {
      require(voters[msg.sender].isEligible, "The sender does not have the right to vote!");
      require((startTime > 0 && endTime > 0), "Polling has not started yet!");
      require(block.number <= endTime, "Polling time is up!");

      voters[msg.sender].optionSelected = option;
      voters[msg.sender].voted = true;
  }

  function getTheWinnerProposal() view public returns(uint winnerIndex_) {

      uint highestVotes = options[0].votes;

      for (uint p = 0; p < options.length; p++) {
          if (options[p].votes > highestVotes) {
              highestVotes = options[p].votes;
              winnerIndex_ = p;
          }
      }
  }

  function getTheWinnerName() external view returns(string memory winnerName_) {
      winnerName_ = options[getTheWinnerProposal()].name;
  }

}