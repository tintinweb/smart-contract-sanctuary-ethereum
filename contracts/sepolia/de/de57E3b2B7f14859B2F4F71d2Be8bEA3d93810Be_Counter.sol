// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

contract Counter {
    bytes32 public number;
    bytes32 public number2;

    constructor(uint256 a) {
        number = bytes32(a);
    }

    function wtfthisworks() public pure returns (uint128) {
        return 1337;
    }

    function ufhjwraiouw() public pure returns (bytes32) {
        return bytes32("gahdamn");
    }

    function dsloakpla() public pure returns (string memory) {
        return "woah";
    } 
}