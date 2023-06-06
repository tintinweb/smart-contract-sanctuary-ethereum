// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract GetSlotLocation {

   constructor() {}   

function arrLocation(uint256 slot, uint256 index, uint256 elementSize) public pure returns (uint256) {
        return uint256(keccak256(abi.encodePacked(slot))) + (index * elementSize) ;
    }
}