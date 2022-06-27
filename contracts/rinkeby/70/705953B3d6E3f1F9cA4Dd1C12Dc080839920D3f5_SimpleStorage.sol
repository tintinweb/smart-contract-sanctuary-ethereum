/**
 *Submitted for verification at Etherscan.io on 2022-06-27
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15; 

contract SimpleStorage {

   
    uint256 public favNumber;
  
     function Store(uint256 _favNumber) public {
         favNumber = _favNumber;
     }                   
}