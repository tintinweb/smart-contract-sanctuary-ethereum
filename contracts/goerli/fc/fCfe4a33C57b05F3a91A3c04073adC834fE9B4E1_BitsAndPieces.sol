// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

contract BitsAndPieces {
    function and(uint256 a, uint256 b) external pure returns (uint256) {
        return a & b;
    }
    function or(uint256 a, uint256 b) external pure returns (uint256) {
        return a | b;
    }
    function xor(uint256 a, uint256 b) external pure returns (uint256) {
        return a ^ b;
    }
    function shiftLeft(uint256 a, uint256 b) external pure returns (uint256) {
        return a << b;
    }
    function shiftRight(uint256 a, uint256 b) external pure returns (uint256) {
        return a >> b;
    }
}