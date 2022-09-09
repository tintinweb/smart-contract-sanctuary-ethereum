/**
 *Submitted for verification at Etherscan.io on 2022-09-09
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

contract ProvablyFair {

    function blockInfo() external view returns(address, uint, uint, uint, uint) {
        return (block.coinbase, block.difficulty, block.gaslimit, block.number, block.timestamp);
    }

    function generateNumber() external view returns (uint) {
        uint index_ = uint(keccak256(abi.encode(block.coinbase, block.difficulty, block.gaslimit, block.number, block.timestamp)));
        return index_;
    }

    function seedABIEncoded(uint seed1, uint seed2, uint nonce) external view returns (bytes memory) {
        return abi.encode(seed1, seed2, nonce, block.coinbase, block.difficulty, block.gaslimit, block.number, block.timestamp);
    }

    function seedKeccak256(uint seed1, uint seed2, uint nonce) external view returns (bytes32) {
        return keccak256(abi.encode(seed1, seed2, nonce, block.coinbase, block.difficulty, block.gaslimit, block.number, block.timestamp));
    }

    function generateNumberSeed(uint seed1, uint seed2, uint nonce) external view returns (uint) {
        return uint(keccak256(abi.encode(seed1, seed2, nonce, block.coinbase, block.difficulty, block.gaslimit, block.number, block.timestamp)));
    }

}