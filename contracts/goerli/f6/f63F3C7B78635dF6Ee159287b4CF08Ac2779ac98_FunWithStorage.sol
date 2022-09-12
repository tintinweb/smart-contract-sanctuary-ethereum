// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract FunWithStorage {
    uint256 favNumber;
    bool someBool;
    uint256[] myArray;

    mapping(uint256 => bool) myMap;

    uint256 constant NOT_IN_STORAGE = 123;
    uint256 immutable i_not_in_storage;

    constructor() {
        favNumber = 25;
        someBool = true;
        myArray.push(222);
        myMap[0] = true;
        i_not_in_storage = 123;
    }

    function doStuff() public view {
        uint256 newVar = favNumber + 1;
        bool otherVar = someBool;
    }
}