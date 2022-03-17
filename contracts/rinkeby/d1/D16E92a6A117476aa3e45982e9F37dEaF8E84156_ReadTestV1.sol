//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

contract ReadTestV1 {
    address public owner;

    uint256[] public uintArray = [1,2,3,4,5,6];

    string[] public stringArray = ["test1","test2","test3"];

    constructor() {
        owner = msg.sender;
    }

    function writeUintArray(uint256[] memory _value) public {
        uintArray = _value;
    }

    function readUintArray() public view returns (uint256[] memory) {
        return uintArray;
    }

    function writeStringArray(string[] memory _value) public {
        stringArray = _value;
    }

    function readStringArray() public view returns (string[] memory) {
        return stringArray;
    }
}