//SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

contract FundWithStorage {
    uint256 favoriteNumber;
    bool someBool;
    uint256[] myArray;
    mapping(uint256 => bool) myMap;
    uint256 constant NOT_IN_STORAGE = 123;
    uint256 immutable i_not_in_storage;

    constructor() {
        favoriteNumber = 25;
        someBool = true;
        myArray.push(222);
        myMap[0] = true;
        i_not_in_storage = 123;
    }

    function doStuff() public {
        uint256 newVar = favoriteNumber + 1;
        bool otherVal = someBool;
    }
}