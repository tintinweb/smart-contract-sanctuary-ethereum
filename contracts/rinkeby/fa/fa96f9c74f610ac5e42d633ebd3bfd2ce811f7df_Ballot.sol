/**
 *Submitted for verification at Etherscan.io on 2022-09-25
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

contract Ballot {
  event OnVote(address indexed candidate);

  mapping(address => uint256) public votes;
  mapping(address => bool) private voters;

  function vote(address candidate) public payable {
    require(!voters[msg.sender], "cannot vote twice");
    votes[candidate]++;
    voters[msg.sender] = true;
    emit OnVote(candidate);
  }
}