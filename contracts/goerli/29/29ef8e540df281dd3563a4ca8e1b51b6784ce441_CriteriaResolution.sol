// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.17;

/// @notice Data estructure used to prove membership to a criteria tree.
/// @dev Account, token & amount are used to encode the leaf.
struct CriteriaResolver {
    // Address that is part of the criteria tree
    address account;
    // Amount of ERC20 token
    uint256 balance;
    // Proof of membership to the tree
    bytes32[] proof;
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.17;

import { CriteriaResolver } from "src/interfaces/CriteriaTypes.sol";

/// @dev Thrown when the proof provided can't be verified against the criteria tree.
error InvalidCriteriaProof();

/// @dev Methods to verify membership to a criteria Merkle tree.
library CriteriaResolution {
    /// @dev Check that given resolver is valid for the provided criteria.
    /// @param criteria Root of the Merkle tree.
    /// @param resolver Struct with the required params to prove membership to the tree.
    function validateCriteria(bytes32 criteria, CriteriaResolver calldata resolver) external pure {
        bool isValid = verifyProof(resolver.proof, criteria, encodeLeaf(resolver));

        if (!isValid) {
            revert InvalidCriteriaProof();
        }
    }

    /// @dev Encode resolver params into merkle leaf
    function encodeLeaf(CriteriaResolver calldata resolver) public pure returns (bytes32 leaf) {
        leaf = keccak256(abi.encode(resolver.account, resolver.balance));
    }

    /// @dev Based on Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/utils/MerkleProofLib.sol)
    ///      Verify proofs for given root and leaf are correct.
    function verifyProof(
        bytes32[] calldata proof,
        bytes32 root,
        bytes32 leaf
    ) public pure returns (bool isValid) {
        /// @solidity memory-safe-assembly
        assembly {
            if proof.length {
                // Left shifting by 5 is like multiplying by 32.
                let end := add(proof.offset, shl(5, proof.length))

                // Initialize offset to the offset of the proof in calldata.
                let offset := proof.offset

                // Iterate over proof elements to compute root hash.
                // prettier-ignore
                for {} 1 {} {
                    // Slot where the leaf should be put in scratch space. If
                    // leaf > calldataload(offset): slot 32, otherwise: slot 0.
                    let leafSlot := shl(5, gt(leaf, calldataload(offset)))

                    // Store elements to hash contiguously in scratch space.
                    // The xor puts calldataload(offset) in whichever slot leaf
                    // is not occupying, so 0 if leafSlot is 32, and 32 otherwise.
                    mstore(leafSlot, leaf)
                    mstore(xor(leafSlot, 32), calldataload(offset))

                    // Reuse leaf to store the hash to reduce stack operations.
                    leaf := keccak256(0, 64) // Hash both slots of scratch space.

                    offset := add(offset, 32) // Shift 1 word per cycle.

                    // prettier-ignore
                    if iszero(lt(offset, end)) { break }
                }
            }

            isValid := eq(leaf, root) // The proof is valid if the roots match.
        }
    }
}