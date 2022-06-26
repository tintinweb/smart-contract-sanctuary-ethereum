// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

/// @title MerkleTests
contract MerkleTests {

    bytes32 public merkleRootSingle;
    bytes32 public merkleRootPacked;

    uint64 private merkleRootsChanged;

    /// Emitted when the Merkle Root is changed by the admin.
    /// @param sender the `msg.sender` (admin) that sets the base URI.
    /// @param merkleRoot the new Merkle Root Hash.
    event MerkleRoot(address sender, bytes32 merkleRoot);

    /// constructor.
    constructor(bytes32 merkleRoot_)
    {
        // Set Merkle Root
        merkleRootSingle = merkleRoot_;
        merkleRootsChanged = 1;
    }

    /// Main public minting function.
    /// @param merkleProof Needed whitelist-check proof
    function proveSingle(bytes32[] calldata merkleProof) public payable returns (uint64) {
        // Require correct proof (validation)
        require(MerkleProof.verify(merkleProof, merkleRootSingle, keccak256(abi.encodePacked(msg.sender))), "Invalid merkle proof");

        // Return iter of root used for proof (validation)
        return merkleRootsChanged;
    }

    /// Set a new Merkle Root Hash at any time.
    /// @param merkleRoot_ The new Merkle Root
    function adminSetMerkleRoot(bytes32 merkleRoot_) external returns (uint64) {
        merkleRootSingle = merkleRoot_;
        merkleRootsChanged++;
        emit MerkleRoot(msg.sender, merkleRoot_);
        return merkleRootsChanged;
    }

    /// Main public minting function.
    /// @param merkleProof Needed whitelist-check proof
    function provePacked(uint64 otherVar, bytes32[] calldata merkleProof) public payable {
        // Require correct proof (validation)
        require(MerkleProof.verify(merkleProof, merkleRootSingle, keccak256(abi.encodePacked(msg.sender, otherVar))), "Invalid merkle proof");
    }

    /// Set a new Merkle Root Hash at any time.
    /// @param merkleRoot_ The new Merkle Root
    function adminSetMerkleRootPacked(bytes32 merkleRoot_) external {
        merkleRootPacked = merkleRoot_;
        emit MerkleRoot(msg.sender, merkleRoot_);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (utils/cryptography/MerkleProof.sol)

pragma solidity ^0.8.0;

/**
 * @dev These functions deal with verification of Merkle Trees proofs.
 *
 * The proofs can be generated using the JavaScript library
 * https://github.com/miguelmota/merkletreejs[merkletreejs].
 * Note: the hashing algorithm should be keccak256 and pair sorting should be enabled.
 *
 * See `test/utils/cryptography/MerkleProof.test.js` for some examples.
 *
 * WARNING: You should avoid using leaf values that are 64 bytes long prior to
 * hashing, or use a hash function other than keccak256 for hashing leaves.
 * This is because the concatenation of a sorted pair of internal nodes in
 * the merkle tree could be reinterpreted as a leaf value.
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

    function _efficientHash(bytes32 a, bytes32 b) private pure returns (bytes32 value) {
        assembly {
            mstore(0x00, a)
            mstore(0x20, b)
            value := keccak256(0x00, 0x40)
        }
    }
}