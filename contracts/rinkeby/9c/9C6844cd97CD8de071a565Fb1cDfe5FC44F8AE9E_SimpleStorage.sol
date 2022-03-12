/**
 *Submitted for verification at Etherscan.io on 2022-03-12
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.12;



// File: SimpleStorage.sol

contract SimpleStorage {
    uint256 number;

    function store(uint256 num) public {
        number = num;
    }

    function retrieve() public view returns (uint256) {
        return number;
    }
}