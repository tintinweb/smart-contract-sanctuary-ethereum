// SPDX-License-Identifier: MIT

pragma solidity >= 0.8.0;

import "./interfaces/IQLF.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

// merkel proof qualification
contract MerkleProofQlf {
    uint32 constant public version = 4;

    constructor() {
    }

    function is_qualified(address account, bytes memory proof)
        virtual
        external
        view
        returns
        (
            bool qualified,
            string memory error_msg
        )
    {
        bytes32[] memory _proof;
        bytes32 merkle_root;
        (proof, merkle_root) = abi.decode(proof, (bytes, bytes32));
        // solhint-disable-next-line
        (_proof) = abi.decode(proof, (bytes32[]));
        // validate whitelist user
        bytes32 leaf = keccak256(abi.encodePacked(account));
        if (MerkleProof.verify(_proof, merkle_root, leaf)) {
            return (true, "");
        }
        return (false, "not qualified");
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >= 0.8.0;

abstract
contract IQLF {
    function version() virtual external view returns (uint32);

    /**
     * @dev Check if the given address is qualified, implemented on demand.
     *
     * Requirements:
     *
     * - `account` account to be checked
     * - `data`  data to prove if a user is qualified.
     *           For instance, it can be a MerkelProof to prove if a user is in a whitelist
     *
     * Return:
     *
     * - `bool` whether the account is qualified for ITO
     * - `string` if not qualified, it contains the error message(reason)
     */
    function is_qualified(address account, bytes memory proof) virtual external view returns (bool, string memory);
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
    function verify(bytes32[] memory proof, bytes32 root, bytes32 leaf) internal pure returns (bool) {
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