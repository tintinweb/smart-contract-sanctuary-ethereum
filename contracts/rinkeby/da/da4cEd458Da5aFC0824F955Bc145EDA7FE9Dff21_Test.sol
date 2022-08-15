//SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

contract Test {
    function getRandomNumber() public view returns (uint) {
        return uint(keccak256(abi.encodePacked(block.timestamp)));
    }
}