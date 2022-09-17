/**
 *Submitted for verification at Etherscan.io on 2022-09-17
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

/** 
 * @title Contract
 * @dev store IPFS hash of a file
 */
contract Contract {
    string ipfsHash;
    
    function setHash(string memory x) public {
        ipfsHash = x;
    }
    
    function getHash() public view returns (string memory x) {
        return ipfsHash;
    }
}