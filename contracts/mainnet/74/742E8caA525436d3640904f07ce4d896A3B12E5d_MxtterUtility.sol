// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

contract MxtterUtility {
    function getHash(uint256 tokenId, uint256 blockNumber) external view returns (bytes32) {
        return
            keccak256(abi.encodePacked(tokenId, blockhash(blockNumber - 1)));
    }
}