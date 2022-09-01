/**
 *Submitted for verification at Etherscan.io on 2022-09-01
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Demo {
    uint256 public stor;

    function Store(uint256 number) public {
        stor = number;
    }

    function GiveBack(uint256 input) public pure returns (uint256) {
        return input + 1;
    }
}