// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

contract TimeBasedAutomation {
    uint256 public counter;

    function automate() external {
        counter++;
    }
}