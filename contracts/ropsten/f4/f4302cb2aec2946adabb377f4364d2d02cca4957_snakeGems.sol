/**
 *Submitted for verification at Etherscan.io on 2022-04-09
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;

contract snakeGems {
  address public owner;
  address public player;
  address public highScorePlayer;

  uint public score;
  uint public maxScore;
  uint public currentScore;
  bool public hasPlayed;


  constructor() {
    owner = msg.sender;
  }

  function writeScore(address currentPlayer, uint _currentScore) public returns(bool highScore){
    if(_currentScore > maxScore) {
      maxScore = _currentScore;
      currentScore = _currentScore;
      score = _currentScore;
      player = currentPlayer;
      highScore = true;
      hasPlayed = true;
      highScorePlayer = currentPlayer;
      return highScore;
    }
    hasPlayed = true;
    player = currentPlayer;
    return highScore;
  }

  
}