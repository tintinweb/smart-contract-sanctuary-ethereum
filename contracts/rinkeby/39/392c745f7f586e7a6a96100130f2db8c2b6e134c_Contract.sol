/**
 *Submitted for verification at Etherscan.io on 2022-05-04
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0;


contract Contract {
 string ipfsHash;
 
 function sendHash( string memory x) public {
   ipfsHash = x;
 }

 function getHash() public view returns ( string memory x) {
   return ipfsHash;
 }
}