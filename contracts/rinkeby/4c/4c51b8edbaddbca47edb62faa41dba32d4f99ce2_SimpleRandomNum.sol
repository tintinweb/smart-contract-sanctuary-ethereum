// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

contract SimpleRandomNum {
    // using block hash and difficulty
    function getRandomNum() public view returns (uint) {
        return uint(keccak256(abi.encodePacked(blockhash(block.number - 1), blockhash(block.difficulty), block.timestamp)));
    }
}