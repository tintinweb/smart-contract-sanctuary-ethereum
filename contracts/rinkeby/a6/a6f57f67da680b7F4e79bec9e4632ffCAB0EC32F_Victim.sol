// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;
 
contract Victim {

   mapping (address => bool) public winners;
    constructor()
    {
        
    }
   function draw(uint256 betGuess) public payable {
     require (msg.value >= 1 ether);
     uint outcome = coinFlip();
     if (outcome == betGuess){
       winners[msg.sender] = true;
     }
   }
 
   function coinFlip() private view returns (uint) {
     return uint(
       keccak256(abi.encodePacked(blockhash(block.number),msg.sender))
     );
   }
 
 }