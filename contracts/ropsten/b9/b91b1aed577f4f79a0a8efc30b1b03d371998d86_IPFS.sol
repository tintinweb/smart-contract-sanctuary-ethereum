/**
 *Submitted for verification at Etherscan.io on 2022-02-15
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.3;
contract IPFS {
 string ipfsHash;
 
 function sendHash(string memory x) public {
   ipfsHash = x;
 }

 function getHash() public view returns (string memory x) {
   return ipfsHash;
 }
}