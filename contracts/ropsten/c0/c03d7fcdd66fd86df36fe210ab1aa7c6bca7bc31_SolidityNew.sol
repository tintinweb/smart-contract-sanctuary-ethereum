/**
 *Submitted for verification at Etherscan.io on 2022-06-03
*/

//SPDX-License-Identifier: Unlicense

pragma solidity ^0.8.0;
contract SolidityNew {
   constructor(){
    
   }
   uint256 public receiveCounter;
   uint256 public fallBackCounter;

   mapping(address => uint256) public reciveBalance;
   mapping(address => uint256) public fallBackBalance;


   receive() external payable{
      receiveCounter++;
      reciveBalance[msg.sender] += msg.value;
   }
   fallback() external payable{
      fallBackCounter++;
      fallBackBalance[msg.sender] += msg.value;
   }
}