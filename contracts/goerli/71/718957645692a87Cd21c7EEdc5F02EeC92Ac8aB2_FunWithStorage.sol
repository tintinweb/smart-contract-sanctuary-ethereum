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
    uint256[] public values = [1, 2, 3, 4, 5, 6, 7, 8];

    constructor() {
        favoriteNumber = 25; // See stored spot above // SSTORE
        someBool = true; // See stored spot above // SSTORE
        myArray.push(222); // SSTORE
        myMap[0] = true; // SSTORE
        i_not_in_storage = 321;
    }

    function doStuff() public view {
        uint256 newVar = favoriteNumber + 1; // SLOAD
        bool otherVar = someBool; // SLOAD
        // ^^ memory variables
    }

    // abi.encode(0) will return 0x0000000000000000000000000000000000000000000000000000000000000000
    // keccak256(abi.encode(0)) will return 0x290decd9548b62a8d60345a988386fc84ba6bc95484008f6362f93160ef3e563
    bytes32 public constant startingIndexOfValuesArrayElementsInStorage =
        keccak256(abi.encode(0));

    function getElementIndexInStorage(uint256 _elementIndex)
        public
        pure
        returns (bytes32)
    {
        return
            bytes32(
                uint256(startingIndexOfValuesArrayElementsInStorage) +
                    _elementIndex
            );
    }
}