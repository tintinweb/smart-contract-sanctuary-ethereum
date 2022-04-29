// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

contract Box {
    uint256 public coins;

    function mintCoin() public {
        coins += 1;
    }
}