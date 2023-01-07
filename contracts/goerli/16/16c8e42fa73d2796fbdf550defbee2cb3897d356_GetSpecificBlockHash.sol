/**
 *Submitted for verification at Etherscan.io on 2023-01-07
*/

// SPDX-License-Identifier: MIT
// aalma

pragma solidity ^0.7.0;

contract GetSpecificBlockHash {
    bytes32 blockHash;

    function getBlockHash(uint256 blockNumber) public {
        blockHash = blockhash(blockNumber);
    }

    function viewBlockHash() public view returns (bytes32) {
        return blockHash;
    }
}