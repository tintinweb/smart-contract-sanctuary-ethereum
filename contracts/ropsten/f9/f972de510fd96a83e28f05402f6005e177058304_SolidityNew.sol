/**
 *Submitted for verification at Etherscan.io on 2022-06-01
*/

//SPDX-License-Identifier: Unlicense

pragma solidity ^0.8.12;
contract SolidityNew {


  uint256 public age;
   function updateAge() public returns(uint256) {

      uint256 data = 1;
      for(uint256 i = 0; i<=5; i++){
         data = data * i;
      }
      data = age;
    
   }
}