// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

contract SimpleRandomNum {
    // using block hash and difficulty
    // uint256 rand;
    function getRandomNum1(uint64 seed) public view returns (uint256) {
        return uint256(keccak256(abi.encodePacked(blockhash(block.number - 1), blockhash(block.difficulty), block.timestamp, seed)));
    }

    function getRandomNum2(uint64 seed) public view returns (uint256) {
        uint256 rand = uint256(keccak256(abi.encodePacked(blockhash(block.number - 1), blockhash(block.difficulty), block.timestamp, seed)));
        return rand;
    }
}