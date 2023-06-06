// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract GetSlotLocation {

   constructor() {}   

function getSlotWithIndex(uint256 index) public pure returns (uint256 storageSlot) {
        uint256 arraySlot = 1;
        uint256 arraySize = type(uint256).max;
        storageSlot= uint256(keccak256(abi.encodePacked(arraySlot))) + (index * arraySize/256);
    }

function getIndexWithSlot(uint256 storageSlot) public pure returns (uint256 index) {
        uint256 arraySlot = 1;
        uint256 arraySize = type(uint256).max;
        index = storageSlot - uint256(keccak256(abi.encodePacked(arraySlot))) * 256/ arraySize;
    }
}