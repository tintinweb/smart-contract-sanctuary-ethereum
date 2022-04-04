/**
 *Submitted for verification at Etherscan.io on 2022-04-04
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

// --
library MerkleProof {
    function verify(
        bytes32[] memory proof,
        bytes32 root,
        bytes32 leaf
    ) internal pure returns (bool) {
        return processProof(proof, leaf) == root;
    }

    function processProof(bytes32[] memory proof, bytes32 leaf)
        internal
        pure
        returns (bytes32)
    {
        bytes32 computedHash = leaf;
        for (uint256 i = 0; i < proof.length; i++) {
            bytes32 proofElement = proof[i];
            if (computedHash <= proofElement) {
                // Hash(current computed hash + current element of the proof)
                computedHash = _efficientHash(computedHash, proofElement);
            } else {
                // Hash(current element of the proof + current computed hash)
                computedHash = _efficientHash(proofElement, computedHash);
            }
        }
        return computedHash;
    }

    function _efficientHash(bytes32 a, bytes32 b)
        private
        pure
        returns (bytes32 value)
    {
        assembly {
            mstore(0x00, a)
            mstore(0x20, b)
            value := keccak256(0x00, 0x40)
        }
    }
}

// --
contract SimpleMerkleTrees {
    using MerkleProof for bytes32[];

    bytes32 public merkleRoot;

    uint256 public counter = 0;

    constructor() {}

    function ping(bytes32[] calldata proof, uint256 number) external {
        require(tx.origin == msg.sender, "Cannot called from contract");
        require(number > 0, "The number must greater than 0");
        require(
            proof.verify(
                merkleRoot,
                keccak256(abi.encodePacked(msg.sender, number))
            ),
            "Failed to verify merkle proof"
        );
        if (counter + number > 256) {
            counter = 0;
        } else {
            counter = counter + number;
        }
    }

    function setMerkleRoot(bytes32 _merkleRoot) external {
        merkleRoot = _merkleRoot;
    }
}