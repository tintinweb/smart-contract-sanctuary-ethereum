// SPDX-License-Identifier: GPL-3.0-only

pragma solidity 0.8.12;

library MerkleLib {

    function verifyProof(bytes32 root, bytes32 leaf, bytes32[] calldata proof) public pure returns (bool) {
        bytes32 currentHash = leaf;

        uint proofLength = proof.length;
        for (uint i; i < proofLength;) {
            currentHash = parentHash(currentHash, proof[i]);
            unchecked { ++i; }
        }

        return currentHash == root;
    }

    function parentHash(bytes32 a, bytes32 b) private pure returns (bytes32) {
        return keccak256(a < b ? abi.encode(a, b) : abi.encode(b, a));
    }

}