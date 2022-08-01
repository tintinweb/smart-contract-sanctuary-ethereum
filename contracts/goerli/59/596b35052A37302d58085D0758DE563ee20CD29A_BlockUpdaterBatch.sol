/**
 *Submitted for verification at Etherscan.io on 2022-08-01
*/

// File: contracts/interface/IEcdsaVerifier.sol



pragma solidity ^0.8.14;

interface IEcdsaVerifier {
    function verifyProof(
        uint256[2] memory a,
        uint256[2][2] memory b,
        uint256[2] memory c,
        uint256[8] memory input
    )  external view returns (bool);
}


// File: @openzeppelin/contracts/utils/cryptography/MerkleProof.sol


// OpenZeppelin Contracts (last updated v4.7.0) (utils/cryptography/MerkleProof.sol)

pragma solidity ^0.8.0;

/**
 * @dev These functions deal with verification of Merkle Tree proofs.
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
     * @dev Returns true if the `leaves` can be proved to be a part of a Merkle tree defined by
     * `root`, according to `proof` and `proofFlags` as described in {processMultiProof}.
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
     * @dev Returns the root of a tree reconstructed from `leaves` and the sibling nodes in `proof`,
     * consuming from one or the other at each step according to the instructions given by
     * `proofFlags`.
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
     * @dev Calldata version of {processMultiProof}
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

// File: contracts/BlockUpdaterBatch.sol



pragma solidity ^0.8.14;



contract BlockUpdaterBatch {

    event MerkleRootRecorded(bytes32 parentMerkleRoot, bytes32 currentMerkleRoot, uint256 blockSize, uint256 blockNumber);

    struct MerkleRootInfo {
        uint256 index;
        uint256 size;
        uint256 blockNumber;
        uint256 totalDifficulty;
    }

    bytes32[] public canonical;

    IEcdsaVerifier ecdsaVerifier;

    mapping(bytes32 => MerkleRootInfo) public merkleRoots;

    constructor(bytes32 merkleRoot, uint256 blockSize, uint256 blockNumber, uint256 totalDifficulty, address ecdsaVerifierAddress) {
        MerkleRootInfo memory tempInfo = MerkleRootInfo(0, blockSize, blockNumber, totalDifficulty);
        merkleRoots[merkleRoot] = tempInfo;
        canonical.push(merkleRoot);
        ecdsaVerifier = IEcdsaVerifier(ecdsaVerifierAddress);
    }

    struct ParsedInput {
        bytes32 parentMerkleRoot;
        bytes32 currentMerkleRoot;
        uint256 validatorSetHash;
        uint256 totalDifficulty;
        uint256 LastBlockNumber;
    }

    function parse_input(uint256[8] memory inputs) public view returns (ParsedInput memory) {
        ParsedInput memory result;
        uint256 parentMTRoot = inputs[0] << 128 | inputs[1];
        result.parentMerkleRoot = bytes32(parentMTRoot);

        uint256 currentMTRoot = inputs[2] << 128 | inputs[3];
        result.currentMerkleRoot = bytes32(currentMTRoot);
        result.totalDifficulty = inputs[4];
        uint256 valSetHash = inputs[5] << 128 | inputs[6];
        result.validatorSetHash = uint256(valSetHash);
        result.LastBlockNumber = inputs[7];
        return result;
    }

    function updateBlock(
        uint256[2] memory a,
        uint256[2][2] memory b,
        uint256[2] memory c,
        uint256[8] memory inputs
    ) public {
        ParsedInput memory parsedInput = parse_input(inputs);
        uint256 blockSize = 32;
        uint256 totalDifficulty = parsedInput.totalDifficulty;
        bytes32 parentMerkleRoot = parsedInput.parentMerkleRoot;
        bytes32 currentMerkleRoot = parsedInput.currentMerkleRoot;
        uint256 blockNumber = parsedInput.LastBlockNumber;

        ecdsaVerifier.verifyProof(a, b, c, inputs);

        // make sure the known block
        MerkleRootInfo storage parentInfo = merkleRoots[parentMerkleRoot];
        require(parentMerkleRoot == canonical[0] || parentInfo.index != 0, 'Cannot find parent');

        MerkleRootInfo memory tempInfo = MerkleRootInfo(parentInfo.index + 1, blockSize, blockNumber, totalDifficulty);
        merkleRoots[currentMerkleRoot] = tempInfo;

        bytes32 h = canonical[canonical.length - 1];
        if (merkleRoots[h].totalDifficulty < totalDifficulty) {
            // reorg
            uint number = 1 + parentInfo.index;
            if (number >= canonical.length) {
                canonical.push(currentMerkleRoot);
            } else {
                canonical[number] = currentMerkleRoot;
                for (uint256 i = canonical.length - 1; i > number; i--) {
                    canonical.pop();
                }
            }
        }
        emit MerkleRootRecorded(parentMerkleRoot, currentMerkleRoot, blockSize, blockNumber);
    }

    function getHighestBlockNumber() public view returns (uint256) {
        uint256 index = canonical.length - 1;
        bytes32 merkleRoot = canonical[index];
        return merkleRoots[merkleRoot].blockNumber;
    }

    function checkBlockHash(bytes32 blockHash, bytes32[] calldata merkleProof) external view returns (bool) {
        bytes32 merkleRoot = MerkleProof.processProof(merkleProof,keccak256(abi.encode(blockHash)));
        MerkleRootInfo memory merkleRootInfo = merkleRoots[merkleRoot];
        if (merkleRoot == canonical[merkleRootInfo.index]) {
            return true;
        }
        return false;
    }
}