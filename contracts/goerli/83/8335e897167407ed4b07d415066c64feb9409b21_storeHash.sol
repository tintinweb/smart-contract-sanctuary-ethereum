/**
 *Submitted for verification at Etherscan.io on 2022-08-28
*/

// SPDX-License-Identifier: UNLICENCED
pragma solidity 0.8.7;

contract storeHash{
    
    string hash;

    function storeImageHash(string memory _hash) public returns(bool){
        hash = _hash;
        return true;
    }

    function getHash() public view returns (string memory){
        return hash;
    }
}