/**
 *Submitted for verification at Etherscan.io on 2022-06-10
*/

// SPDX-License-Identifier: MIT 

pragma solidity ^0.8.11; 

contract HelloWorld { 
   string public name; 

   function setName (string memory newName) public { 
     name=newName; 
   } 

   function getGreeting() public view returns (string memory) { 
     return string(abi.encodePacked("Hello, ", name)); 
   } 
}