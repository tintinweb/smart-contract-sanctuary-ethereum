// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

contract Xor {
    function calculate(string memory a, string memory b) external pure returns (uint256) {
        return uint256(keccak256(abi.encodePacked(a)) ^ keccak256(abi.encodePacked(b)));
    }
}