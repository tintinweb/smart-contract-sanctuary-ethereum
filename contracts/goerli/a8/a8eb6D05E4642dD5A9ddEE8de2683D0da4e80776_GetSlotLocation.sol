// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract GetSlotLocation {

   constructor() {}   

function getSlotWithIndex(uint256 arraySlot, uint256 index) public pure returns (uint256 storageSlot) {
        storageSlot= uint256(keccak256(abi.encodePacked(arraySlot))) + index;
    }

function getIndexWithSlot(uint256 arraySlot, uint256 storageSlot) public pure returns (uint256 index) {
        index = type(uint256).max - storageSlot - uint256(keccak256(abi.encodePacked(arraySlot))) ;
    }
}



// https://ethereum.stackexchange.com/questions/106526/how-to-locate-value-from-dynamic-array-in-the-storage