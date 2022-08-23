/**
 *Submitted for verification at Etherscan.io on 2022-08-23
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.8;  // ^0.8.7 version above 0.8.7 is okay. >=0.8.7 <0.8.12 means 0.8.7 ~ 0.8.11 is okay.

contract SimpleStorage {
    // boolean, uint, int, address, bytes
    uint public favoriteNumber; //uint = uint256, default is 0; default is internal

    function store(uint256 _number) public {
        favoriteNumber = _number;

    } 
    
}

// 0xa131AD247055FD2e2aA8b156A11bdEc81b9eAD95