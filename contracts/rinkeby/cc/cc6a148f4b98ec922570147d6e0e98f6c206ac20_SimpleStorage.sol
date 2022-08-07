/**
 *Submitted for verification at Etherscan.io on 2022-08-07
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.4;


contract SimpleStorage {

    uint256 savedNumber;

    function store(uint256 num) public {
        savedNumber = num;
    }

    function retrieve() public view returns (uint256){
        return savedNumber;
    }
}