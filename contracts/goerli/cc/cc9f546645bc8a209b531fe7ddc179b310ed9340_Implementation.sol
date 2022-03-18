/**
 *Submitted for verification at Etherscan.io on 2022-03-18
*/

/// SPDX-License-Identifier: GPL-3
pragma solidity = 0.8.13;

contract Implementation {
    address public implementation;

    event FunctionOne(bool param1, uint256 param2);
    event FunctionTwo(uint256 param1);

    function one(bool param1, uint256 param2) external {
        emit FunctionOne(param1, param2);
    }

    function two(uint256 param1) external {
        emit FunctionTwo(param1);
    }
}