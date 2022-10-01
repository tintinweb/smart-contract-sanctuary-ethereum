// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

contract SmartContract {
    uint256 age;

    constructor() {
        age = 23;
    }

    function getAge() public view returns (uint256) {
        return age;
    }
}