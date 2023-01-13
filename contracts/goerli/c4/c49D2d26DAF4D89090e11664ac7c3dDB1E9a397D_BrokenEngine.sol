// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.7;

contract BrokenEngine {
    function assassin() public {
        selfdestruct(payable(address(0)));
    }
}