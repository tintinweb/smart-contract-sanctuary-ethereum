/**
 *Submitted for verification at Etherscan.io on 2022-04-14
*/

pragma solidity ^0.8.0;
//SPDX-License-Identifier: MIT

  contract Score {

    uint  score = 0;
    
    function showScore() public view returns(uint){
      return score;

    }

    function updateScore() public {
      score = score + 1;

    }

    function decreaseScore() public {
      score = score - 1;

    }
  }