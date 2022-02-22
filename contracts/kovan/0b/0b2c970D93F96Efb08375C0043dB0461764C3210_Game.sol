/**
 *Submitted for verification at Etherscan.io on 2022-02-22
*/

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

contract Game {
    
    event Score(address player, uint256 score);
    address public highScorer;
    uint256 public highScore;

    constructor() {
        highScorer = address(0);
        highScore = 0;
    }

    function score(address player, uint256 score) public {
        if(score > highScore){
            highScorer = player;
            highScore = score;
        }
        emit Score(player, score);
    }

}