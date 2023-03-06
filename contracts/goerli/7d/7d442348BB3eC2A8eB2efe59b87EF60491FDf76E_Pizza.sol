/**
 *Submitted for verification at Etherscan.io on 2023-03-06
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;


contract Pizza {
   //inherited by child contracts
   uint256 internal slices;


   event SlicesLeft(uint256 left);
 

 //in upgradeable contracts we cannot use a constructor, instead we use a fuction named initialize
   function initialize(uint256 _slices) public {
       slices = _slices;
   }


   function eatSlice() external {
       require(slices >= 1, "No slices left.");
       slices -= 1;
       emit SlicesLeft(slices);
   }


   function slicesLeft() external view returns (uint256) {
       return slices;
   }
}