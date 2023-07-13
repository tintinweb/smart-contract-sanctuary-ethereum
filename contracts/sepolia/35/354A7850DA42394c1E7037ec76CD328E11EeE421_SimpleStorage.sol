// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;
// nilay's github solidity ethereum contract
contract SimpleStorage {
    string public name;
    uint256 public num;
    constructor() {
        name = "Hello";
        num = 43;
    }
    function getStr() public view returns(string memory) {
        return name;
    }

    function getNum() public view returns(uint256) {
        return num;
    }
}