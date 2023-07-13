// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

contract SimpleStorage {
    string public name;
    constructor() {
        name = "Hello";
    }
    function getStr() public view returns(string memory) {
        return name;
    }
}