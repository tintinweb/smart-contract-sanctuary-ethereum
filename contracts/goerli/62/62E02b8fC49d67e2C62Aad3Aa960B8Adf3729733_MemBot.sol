// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

contract MemBot {
    uint256 public count;
    function check(address _from) external {
        count + 1;
    }
}