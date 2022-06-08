// SPDX-License-Identifier: MIT
// Project assets are CC0
pragma solidity ^0.8.13;

contract GasLimit {
    function limit() public view returns (uint256) {
        return gasleft();
    }
}