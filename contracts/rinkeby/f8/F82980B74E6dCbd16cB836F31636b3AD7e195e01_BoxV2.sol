// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

contract BoxV2 {
    uint256 public coins;

    function mintCoin() public {
        coins += 1;
    }

    function addCoin(uint256 coinNum) public {
        coins += coinNum;
    }
}