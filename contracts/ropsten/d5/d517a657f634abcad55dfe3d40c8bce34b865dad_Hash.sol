/**
 *Submitted for verification at Etherscan.io on 2022-07-17
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;
contract Hash { 
   function hash(string memory _string) public pure returns(bytes32) 
   {
     return sha256(abi.encodePacked(_string));

   } 
}