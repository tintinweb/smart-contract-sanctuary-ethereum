// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

contract SimpleStorage {
    address public immutable i_owner;
    uint8 testNum;

    constructor() {
        i_owner = msg.sender;
    }

    function test() public view returns (address) {
        return i_owner;
        //return (msg.sender == i_owner);
    }

    function store(uint8 _testNum) public {
        testNum = _testNum;
    }

    function retrieve() public view returns (uint8) {
        return testNum;
    }
}