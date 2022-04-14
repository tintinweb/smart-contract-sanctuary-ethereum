// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.10;

import '@openzeppelin/contracts/utils/cryptography/MerkleProof.sol';

library MerkleClaim {
    event Claimed(uint256 indexed index);

    struct ClaimParams {
        uint256 index;
        bytes claimData;
        bytes32 messageSignature;
        bytes32 entropy;
        bytes32[] proof;
    }

    struct MerkleData {
        bytes32 merkleRoot;
        mapping(uint256 => uint256) _claimedBitMap; // max (2**256 - 1) * 256
    }

    function claim(MerkleData storage data, ClaimParams memory params) external {
        _requireClaimable(data, params);

        _setClaimed(data, params.index);
        // (bool success, bytes memory result) = address(this).call(params.claimData);
        // if (!success) {
        //     assembly {
        //         result := add(result, 0x04)
        //     }
        //     revert(abi.decode(result, (string)));
        // }
        (bool success, ) = address(this).call(params.claimData);
        require(success, 'LMC_CLAIM_FAILED');

        emit Claimed(params.index);
    }

    function _requireClaimable(MerkleData storage data, ClaimParams memory params) public view {
        require(!isClaimed(data, params.index), 'LMC_ALREADY_CLAIMED');

        bytes32 node = keccak256(
            abi.encode(params.index, msg.sender, params.claimData, params.messageSignature, params.entropy)
        );

        require(MerkleProof.verify(params.proof, data.merkleRoot, node), 'LMC_INVALID_PROOF');
    }

    function isClaimed(MerkleData storage data, uint256 index) public view returns (bool) {
        uint256 claimedWordIndex = index / 256;
        uint256 claimedBitIndex = index % 256;
        uint256 claimedWord = data._claimedBitMap[claimedWordIndex];
        uint256 mask = (1 << claimedBitIndex);
        return claimedWord & mask == mask;
    }

    function _setClaimed(MerkleData storage data, uint256 index) public {
        uint256 claimedWordIndex = index / 256;
        uint256 claimedBitIndex = index % 256;
        data._claimedBitMap[claimedWordIndex] = data._claimedBitMap[claimedWordIndex] | (1 << claimedBitIndex);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/cryptography/MerkleProof.sol)

pragma solidity ^0.8.0;

/**
 * @dev These functions deal with verification of Merkle Trees proofs.
 *
 * The proofs can be generated using the JavaScript library
 * https://github.com/miguelmota/merkletreejs[merkletreejs].
 * Note: the hashing algorithm should be keccak256 and pair sorting should be enabled.
 *
 * See `test/utils/cryptography/MerkleProof.test.js` for some examples.
 */
library MerkleProof {
    /**
     * @dev Returns true if a `leaf` can be proved to be a part of a Merkle tree
     * defined by `root`. For this, a `proof` must be provided, containing
     * sibling hashes on the branch from the leaf to the root of the tree. Each
     * pair of leaves and each pair of pre-images are assumed to be sorted.
     */
    function verify(
        bytes32[] memory proof,
        bytes32 root,
        bytes32 leaf
    ) internal pure returns (bool) {
        return processProof(proof, leaf) == root;
    }

    /**
     * @dev Returns the rebuilt hash obtained by traversing a Merklee tree up
     * from `leaf` using `proof`. A `proof` is valid if and only if the rebuilt
     * hash matches the root of the tree. When processing the proof, the pairs
     * of leafs & pre-images are assumed to be sorted.
     *
     * _Available since v4.4._
     */
    function processProof(bytes32[] memory proof, bytes32 leaf) internal pure returns (bytes32) {
        bytes32 computedHash = leaf;
        for (uint256 i = 0; i < proof.length; i++) {
            bytes32 proofElement = proof[i];
            if (computedHash <= proofElement) {
                // Hash(current computed hash + current element of the proof)
                computedHash = keccak256(abi.encodePacked(computedHash, proofElement));
            } else {
                // Hash(current element of the proof + current computed hash)
                computedHash = keccak256(abi.encodePacked(proofElement, computedHash));
            }
        }
        return computedHash;
    }
}