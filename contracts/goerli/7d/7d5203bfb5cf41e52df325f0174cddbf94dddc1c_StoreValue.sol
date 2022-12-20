/**
 *Submitted for verification at Etherscan.io on 2022-12-19
*/

// SPDX-License-Identifier: MIT

/*
    Howdy!
    
    This contract stores a value in the blockchain.
*/

pragma solidity ^0.8.0;

contract StoreValue {
    uint256 myVal;

    function store(uint256 _myVal) public {
        myVal = _myVal;
    }

    function retrieve() public view returns (uint256) {
        return myVal;
    }
}