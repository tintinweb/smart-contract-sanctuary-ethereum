// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

contract FunWithStorage {
    uint256 favoriteNumber; // Stored at slot 0
    bool someBool; // Stored at slot 1
    uint256[] myArray; /* Array Length Stored at slot 2,
    but the objects will be the keccak256(2), since 2 is the storage slot of the array */
    mapping(uint256 => bool) myMap; /* An empty slot is held at slot 3
    and the elements will be stored at keccak256(h(k) . p)

    p: The storage slot (aka, 3)
    k: The key in hex
    h: Some function based on the type. For uint256, it just pads the hex
    */
    uint256 constant NOT_IN_STORAGE = 123;
    uint256 immutable i_not_in_storage;

    constructor() {
        favoriteNumber = 25; // See stored spot above // SSTORE
        someBool = true; // See stored spot above // SSTORE
        myArray.push(222); // SSTORE
        myMap[0] = true; // SSTORE
        i_not_in_storage = 123;
    }

    function doStuff() public {
        // Below are not stored in storage
        uint256 newVar = favoriteNumber + 1; // SLOAD
        bool otherVar = someBool; // SLOAD
        // ^^ memory variables
    }

    // JavaScript Doesn't Support Functions That Return Multiple Values!!!
    // But we can make dictionary to read it...
    function getBoth(uint256 _yourNumber) public view returns (uint256[] memory, bool) {
        return (myArray, myMap[_yourNumber]);
    }

    function getArray() public view returns (uint256[] memory) {
        return myArray;
    }

    function getMap(uint256 _yourNumber) public view returns (bool) {
        return myMap[_yourNumber];
    }
}