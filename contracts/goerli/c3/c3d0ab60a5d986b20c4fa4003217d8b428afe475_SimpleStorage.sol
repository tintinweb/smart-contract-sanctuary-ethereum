/**
 *Submitted for verification at Etherscan.io on 2022-10-18
*/

// SPDX-License-Identifier: GPL-3.0
 
pragma solidity 0.8.13;
 
contract SimpleStorage {
   uint data;
 
   function set(uint x) public {
       data = x;
   }
 
   function get() public view returns (uint) {
       return data;
   }
}