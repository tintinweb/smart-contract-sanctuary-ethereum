/**
 *Submitted for verification at Etherscan.io on 2022-05-05
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract IPFS {
    string ipfsHash;
    
    function sendHash(string memory x) public {
        ipfsHash = x;
    }
    
    function getHash() public view returns (string memory) {
        return ipfsHash;
    }
}