// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

/**
 * @title Hypernet Protocol Merkle Drop Module for NFRs
 * @author Todd Chapman
 * @dev Implementation of a Merkle Drop meta-transaction extension for NFRs
 *
 * See the documentation for more details:
 * https://docs.hypernet.foundation/hypernet-protocol/identity/modules#merkle-drop
 *
 * See the unit tests for example usage:
 * https://github.com/GoHypernet/hypernet-protocol/blob/dev/packages/contracts/test/upgradeable-registry-enumerable-test.js#L665
 */
contract MerkleModule {

    /// @dev the name to be listed in the Hypernet Protocol Registry Modules NFR
    /// @dev see https://docs.hypernet.foundation/hypernet-protocol/identity#registry-modules
    string public name; 

    constructor(string memory _name)
    {
        name = _name; 
    }

    /// @notice redeem offload gas cost of minting to receivers
    /// @dev scalable distribution of NFIs
    /// @param to address of the recipient of the token
    /// @param label a unique label to attach to the token
    /// @param registrationData data to store in the tokenURI
    /// @param tokenId unique uint256 identifier for the newly created token
    /// @param proof merkle traversal proof (see merkletreejs)
    /// @param registry address of the target NFR
    function redeem(address to, string calldata label, string calldata registrationData, uint256 tokenId, bytes32[] calldata proof, address registry)
    external
    {
        bytes32 root = INfr(registry).merkleRoot();
        require(_verify(_leaf(to, label, registrationData, tokenId), proof, root), "MerkleModule: Invalid merkle proof");
        INfr(registry).register(to, label, registrationData, tokenId);
    }

    function _leaf(address to, string calldata label, string calldata registrationData, uint256 tokenId)
    internal pure returns (bytes32)
    {
        return keccak256(abi.encodePacked(to, label, registrationData, tokenId));
    }

    function _verify(bytes32 leaf, bytes32[] memory proof, bytes32 root)
    internal pure returns (bool)
    {
        return MerkleProof.verify(proof, root, leaf);
    }
}

/// @dev a minimal interface for interacting with Hypernet Protocol NFRs
interface INfr {
    function register(address to, string calldata label, string calldata registrationData, uint256 tokenId) external;
    function merkleRoot() external view returns (bytes32);
}

// SPDX-License-Identifier: MIT

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

        // Check if the computed hash (root) is equal to the provided root
        return computedHash == root;
    }
}