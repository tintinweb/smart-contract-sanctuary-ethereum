// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

contract Counter {
    bytes32 public number;
    bytes32 public number2;

    constructor(uint256 a) {
        number = bytes32(a);
    }

    function nyannyan() public pure returns (uint128) {
        return 42069;
    }

    function beppboop() public pure returns (bytes32) {
        return bytes32("odra");
    }

    function dyslexia() public pure returns (string memory) {
        return "woah";
    } 
}