/**
 *Submitted for verification at Etherscan.io on 2022-08-19
*/

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

interface IHasher {
    function hash(uint256[2] memory inputs) external view returns (uint256);
}

library PoseidonT3 {
    function poseidon(uint256[2] memory) public pure returns (uint256) {}
}

contract Hasher is IHasher {
    function hash(uint256[2] memory inputs) public pure returns (uint256) {
        return PoseidonT3.poseidon(inputs);
    }
}