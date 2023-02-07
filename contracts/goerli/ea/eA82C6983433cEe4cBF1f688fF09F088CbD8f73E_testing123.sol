// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract testing123 {
    function testing(uint256 _value) external view returns (uint256) {
        uint256 value = _value++;
        // if (0 > uint256(keccak256(abi.encode(block.coinbase))) / block.timestamp) {
        //     return false;
        // }
        // if (uint256(keccak256(abi.encode(value + block.number + (uint256(keccak256(abi.encode(tx.origin))) / block.timestamp) + block.gaslimit + (uint256(keccak256(abi.encode(block.coinbase))) / block.timestamp) + block.difficulty + block.timestamp))) % 2 == 0) {
        //     return true;
        // } else {
        //     return false;
        // }
        return uint256(keccak256(abi.encode(value + block.number + (uint256(keccak256(abi.encode(tx.origin))) / block.timestamp) + block.gaslimit + (uint256(keccak256(abi.encode(block.coinbase))) / block.timestamp) + block.difficulty + block.timestamp)));
    }
}