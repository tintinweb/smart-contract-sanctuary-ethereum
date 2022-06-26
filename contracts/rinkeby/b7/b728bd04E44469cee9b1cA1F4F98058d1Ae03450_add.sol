// SPDX-License-Identifier: MIT

pragma solidity 0.6.11;

contract add {
    function addition(uint256 x, uint256 y) public pure returns (uint256 sum) {
        sum = x+y;
    }
}