// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/cryptography/MerkleProof.sol)

pragma solidity ^0.8.0;

/**
 * @dev These functions deal with verification of Merkle Tree proofs.
 *
 * The tree and the proofs can be generated using our
 * https://github.com/OpenZeppelin/merkle-tree[JavaScript library].
 * You will find a quickstart guide in the readme.
 *
 * WARNING: You should avoid using leaf values that are 64 bytes long prior to
 * hashing, or use a hash function other than keccak256 for hashing leaves.
 * This is because the concatenation of a sorted pair of internal nodes in
 * the merkle tree could be reinterpreted as a leaf value.
 * OpenZeppelin's JavaScript library generates merkle trees that are safe
 * against this attack out of the box.
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
     * @dev Calldata version of {verify}
     *
     * _Available since v4.7._
     */
    function verifyCalldata(
        bytes32[] calldata proof,
        bytes32 root,
        bytes32 leaf
    ) internal pure returns (bool) {
        return processProofCalldata(proof, leaf) == root;
    }

    /**
     * @dev Returns the rebuilt hash obtained by traversing a Merkle tree up
     * from `leaf` using `proof`. A `proof` is valid if and only if the rebuilt
     * hash matches the root of the tree. When processing the proof, the pairs
     * of leafs & pre-images are assumed to be sorted.
     *
     * _Available since v4.4._
     */
    function processProof(bytes32[] memory proof, bytes32 leaf) internal pure returns (bytes32) {
        bytes32 computedHash = leaf;
        for (uint256 i = 0; i < proof.length; i++) {
            computedHash = _hashPair(computedHash, proof[i]);
        }
        return computedHash;
    }

    /**
     * @dev Calldata version of {processProof}
     *
     * _Available since v4.7._
     */
    function processProofCalldata(bytes32[] calldata proof, bytes32 leaf) internal pure returns (bytes32) {
        bytes32 computedHash = leaf;
        for (uint256 i = 0; i < proof.length; i++) {
            computedHash = _hashPair(computedHash, proof[i]);
        }
        return computedHash;
    }

    /**
     * @dev Returns true if the `leaves` can be simultaneously proven to be a part of a merkle tree defined by
     * `root`, according to `proof` and `proofFlags` as described in {processMultiProof}.
     *
     * CAUTION: Not all merkle trees admit multiproofs. See {processMultiProof} for details.
     *
     * _Available since v4.7._
     */
    function multiProofVerify(
        bytes32[] memory proof,
        bool[] memory proofFlags,
        bytes32 root,
        bytes32[] memory leaves
    ) internal pure returns (bool) {
        return processMultiProof(proof, proofFlags, leaves) == root;
    }

    /**
     * @dev Calldata version of {multiProofVerify}
     *
     * CAUTION: Not all merkle trees admit multiproofs. See {processMultiProof} for details.
     *
     * _Available since v4.7._
     */
    function multiProofVerifyCalldata(
        bytes32[] calldata proof,
        bool[] calldata proofFlags,
        bytes32 root,
        bytes32[] memory leaves
    ) internal pure returns (bool) {
        return processMultiProofCalldata(proof, proofFlags, leaves) == root;
    }

    /**
     * @dev Returns the root of a tree reconstructed from `leaves` and sibling nodes in `proof`. The reconstruction
     * proceeds by incrementally reconstructing all inner nodes by combining a leaf/inner node with either another
     * leaf/inner node or a proof sibling node, depending on whether each `proofFlags` item is true or false
     * respectively.
     *
     * CAUTION: Not all merkle trees admit multiproofs. To use multiproofs, it is sufficient to ensure that: 1) the tree
     * is complete (but not necessarily perfect), 2) the leaves to be proven are in the opposite order they are in the
     * tree (i.e., as seen from right to left starting at the deepest layer and continuing at the next layer).
     *
     * _Available since v4.7._
     */
    function processMultiProof(
        bytes32[] memory proof,
        bool[] memory proofFlags,
        bytes32[] memory leaves
    ) internal pure returns (bytes32 merkleRoot) {
        // This function rebuild the root hash by traversing the tree up from the leaves. The root is rebuilt by
        // consuming and producing values on a queue. The queue starts with the `leaves` array, then goes onto the
        // `hashes` array. At the end of the process, the last hash in the `hashes` array should contain the root of
        // the merkle tree.
        uint256 leavesLen = leaves.length;
        uint256 totalHashes = proofFlags.length;

        // Check proof validity.
        require(leavesLen + proof.length - 1 == totalHashes, "MerkleProof: invalid multiproof");

        // The xxxPos values are "pointers" to the next value to consume in each array. All accesses are done using
        // `xxx[xxxPos++]`, which return the current value and increment the pointer, thus mimicking a queue's "pop".
        bytes32[] memory hashes = new bytes32[](totalHashes);
        uint256 leafPos = 0;
        uint256 hashPos = 0;
        uint256 proofPos = 0;
        // At each step, we compute the next hash using two values:
        // - a value from the "main queue". If not all leaves have been consumed, we get the next leaf, otherwise we
        //   get the next hash.
        // - depending on the flag, either another value for the "main queue" (merging branches) or an element from the
        //   `proof` array.
        for (uint256 i = 0; i < totalHashes; i++) {
            bytes32 a = leafPos < leavesLen ? leaves[leafPos++] : hashes[hashPos++];
            bytes32 b = proofFlags[i] ? leafPos < leavesLen ? leaves[leafPos++] : hashes[hashPos++] : proof[proofPos++];
            hashes[i] = _hashPair(a, b);
        }

        if (totalHashes > 0) {
            return hashes[totalHashes - 1];
        } else if (leavesLen > 0) {
            return leaves[0];
        } else {
            return proof[0];
        }
    }

    /**
     * @dev Calldata version of {processMultiProof}.
     *
     * CAUTION: Not all merkle trees admit multiproofs. See {processMultiProof} for details.
     *
     * _Available since v4.7._
     */
    function processMultiProofCalldata(
        bytes32[] calldata proof,
        bool[] calldata proofFlags,
        bytes32[] memory leaves
    ) internal pure returns (bytes32 merkleRoot) {
        // This function rebuild the root hash by traversing the tree up from the leaves. The root is rebuilt by
        // consuming and producing values on a queue. The queue starts with the `leaves` array, then goes onto the
        // `hashes` array. At the end of the process, the last hash in the `hashes` array should contain the root of
        // the merkle tree.
        uint256 leavesLen = leaves.length;
        uint256 totalHashes = proofFlags.length;

        // Check proof validity.
        require(leavesLen + proof.length - 1 == totalHashes, "MerkleProof: invalid multiproof");

        // The xxxPos values are "pointers" to the next value to consume in each array. All accesses are done using
        // `xxx[xxxPos++]`, which return the current value and increment the pointer, thus mimicking a queue's "pop".
        bytes32[] memory hashes = new bytes32[](totalHashes);
        uint256 leafPos = 0;
        uint256 hashPos = 0;
        uint256 proofPos = 0;
        // At each step, we compute the next hash using two values:
        // - a value from the "main queue". If not all leaves have been consumed, we get the next leaf, otherwise we
        //   get the next hash.
        // - depending on the flag, either another value for the "main queue" (merging branches) or an element from the
        //   `proof` array.
        for (uint256 i = 0; i < totalHashes; i++) {
            bytes32 a = leafPos < leavesLen ? leaves[leafPos++] : hashes[hashPos++];
            bytes32 b = proofFlags[i] ? leafPos < leavesLen ? leaves[leafPos++] : hashes[hashPos++] : proof[proofPos++];
            hashes[i] = _hashPair(a, b);
        }

        if (totalHashes > 0) {
            return hashes[totalHashes - 1];
        } else if (leavesLen > 0) {
            return leaves[0];
        } else {
            return proof[0];
        }
    }

    function _hashPair(bytes32 a, bytes32 b) private pure returns (bytes32) {
        return a < b ? _efficientHash(a, b) : _efficientHash(b, a);
    }

    function _efficientHash(bytes32 a, bytes32 b) private pure returns (bytes32 value) {
        /// @solidity memory-safe-assembly
        assembly {
            mstore(0x00, a)
            mstore(0x20, b)
            value := keccak256(0x00, 0x40)
        }
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

struct MooarNFTLaunchStatus {
    bool isMooarLaunched;
    bool isMooarUnlaunched;

    bytes32 tokenMerkleRoot;
    uint256 redeemMintStartTime;
    uint256 unfreezeMintStartTime;

    bytes32 priorityMerkleRoot;
    uint256 priorityMintStartTime;
    uint256 directMintStartTime;
}

library MooarNFTHelper {
    
    function onlyRedeemMinting(MooarNFTLaunchStatus storage self) public view {
        require(self.isMooarLaunched, "Only for mooar launched NFT");
        require(self.redeemMintStartTime > 0 && block.timestamp >= self.redeemMintStartTime, "Not redeem minting");
    }

    function onlyUnfreezeMinting(MooarNFTLaunchStatus storage self) public view {
        require(self.isMooarLaunched, "Only for mooar launched NFT");
        require(self.unfreezeMintStartTime > 0 && block.timestamp >= self.unfreezeMintStartTime, "Not unfreeze minting");
    }

    function onlyPriorityMinting(MooarNFTLaunchStatus storage self) private view {
        require(self.isMooarUnlaunched, "Only for mooar unlaunched NFT");
        require(self.priorityMintStartTime > 0 && block.timestamp >= self.priorityMintStartTime && block.timestamp < self.directMintStartTime, "Not priority minting");
    }
    
    function onlyDirectMinting(MooarNFTLaunchStatus storage self) private view {
        require(self.isMooarUnlaunched, "Only for mooar unlaunched NFT");
        require(self.directMintStartTime > 0 && block.timestamp >= self.directMintStartTime, "Not direct minting");
    }

    function onlyMintByETH(uint256 ethMintCost) private view {
        require(ethMintCost > 0, "Can't mint by ETH");
        require(msg.value == ethMintCost, "Invalid ETH value");
    }

    function onlyMintByToken(address tokenMintBaseToken, uint256 tokenMintCost) private pure {
        require(tokenMintBaseToken != address(0), "Can't mint by token");
        require(tokenMintCost > 0, "Can't mint by token");
    }
    
    function verifyTokenMerkleProof(address account, bytes32 tokenMerkleRoot, uint256 tokenId, bytes32[] calldata merkleProof) internal pure {
        require(tokenMerkleRoot != bytes32(0), "No merkle root");
        bytes32 node = keccak256(abi.encodePacked(tokenId, account));
        require(MerkleProof.verify(merkleProof, tokenMerkleRoot, node) == true, "Fail to verify proof");
    }

    function verifyAccountMerkleProof(address account, bytes32 accountMerkleRoot, bytes32[] calldata merkleProof) internal pure {
        require(accountMerkleRoot != bytes32(0), "No priority merkle root");
        bytes32 node = keccak256(abi.encodePacked(account));
        require(MerkleProof.verify(merkleProof, accountMerkleRoot, node) == true, "Fail to verify proof");
    }

    function verifyRedeemMint(address account, MooarNFTLaunchStatus storage status, uint256 tokenId, bytes32[] calldata merkleProof) public view {
        onlyRedeemMinting(status);
        verifyTokenMerkleProof(account, status.tokenMerkleRoot, tokenId, merkleProof);
    }

    function verifyUnfreezeMintByETH(uint256 ethMintCost, MooarNFTLaunchStatus storage status, uint256 tokenId, bytes32[] calldata merkleProof) public view {
        onlyUnfreezeMinting(status);
        onlyMintByETH(ethMintCost);
        verifyTokenMerkleProof(address(0), status.tokenMerkleRoot, tokenId, merkleProof);
    }

    function verifyUnfreezeMintByToken(address tokenMintBaseToken, uint256 tokenMintCost, MooarNFTLaunchStatus storage status, uint256 tokenId, bytes32[] calldata merkleProof) public view {
        onlyUnfreezeMinting(status);
        onlyMintByToken(tokenMintBaseToken, tokenMintCost);
        verifyTokenMerkleProof(address(0), status.tokenMerkleRoot, tokenId, merkleProof);
    }

    function verifyPriorityMintByETH(address account, uint256 ethMintCost, MooarNFTLaunchStatus storage status, bytes32[] calldata merkleProof) public view {
        onlyPriorityMinting(status);
        onlyMintByETH(ethMintCost);
        verifyAccountMerkleProof(account, status.priorityMerkleRoot, merkleProof);
    }

    function verifyPriorityMintByToken(address account, address tokenMintBaseToken, uint256 tokenMintCost, MooarNFTLaunchStatus storage status, bytes32[] calldata merkleProof) public view {
        onlyPriorityMinting(status);
        onlyMintByToken(tokenMintBaseToken, tokenMintCost);
        verifyAccountMerkleProof(account, status.priorityMerkleRoot, merkleProof);
    }

    function verifyDirectMintByETH(uint256 ethMintCost, MooarNFTLaunchStatus storage status) public view {
        onlyDirectMinting(status);
        onlyMintByETH(ethMintCost);
    }

    function verifyDirectMintByToken(address tokenMintBaseToken, uint256 tokenMintCost, MooarNFTLaunchStatus storage status) public view {
        onlyDirectMinting(status);
        onlyMintByToken(tokenMintBaseToken, tokenMintCost);
    }
}