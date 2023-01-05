// SPDX-License-Identifier: Mit
pragma solidity ^0.8.7;

contract Test_1 {
    uint256 favoriteNumber;
    bool someBool;
    uint256[] myArray;
    mapping(uint256 => bool) myMapping;

    uint256 constant NOT_IN_STORAGE = 123;
    uint256 immutable i_not_in_storage;

    constructor() {
        i_not_in_storage = 456;

        favoriteNumber = 25;
        someBool = true;
        myArray.push(330);
        myMapping[0] = false;
    }

    function changeMapping(uint256 key, bool value) public {
        myMapping[key] = value;

        favoriteNumber += 1;
    }

    function getFavorityNumer() public view returns (uint256) {
        return favoriteNumber;
    }

    function getArrayByIndex(uint256 index) public view returns (uint256) {
        return myArray[index];
    }
}