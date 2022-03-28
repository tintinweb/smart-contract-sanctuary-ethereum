//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

contract SFR {
  mapping(address => mapping(address => uint8)) public votes;
  uint8 public constant UP_VOTE = 1;
  uint8 public constant DOWN_VOTE = 2;

  function upvote(address c) public {
    votes[c][msg.sender] = UP_VOTE;
  }

  function downvote(address c) public {
    votes[c][msg.sender] = DOWN_VOTE;
  }
}