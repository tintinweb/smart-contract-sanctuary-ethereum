// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

contract BitsAndPieces {
    function and(bytes1 a, bytes1 b) external pure returns (bytes1) {
        return a & b;
    }
    function or(bytes1 a, bytes1 b) external pure returns (bytes1) {
        return a | b;
    }
    function xor(bytes1 a, bytes1 b) external pure returns (bytes1) {
        return a ^ b;
    }
    function shiftLeft(uint256 a, uint256 b) external pure returns (uint256) {
        return a << b;
    }
    function shiftRight(uint256 a, uint256 b) external pure returns (uint256) {
        return a >> b;
    }
}